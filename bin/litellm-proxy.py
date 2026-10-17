#!/usr/bin/env python3
"""
Local reverse proxy that works around two LiteLLM/Zed-family gaps:

1. Caching: neither the Anthropic Messages (/v1/messages) nor the OpenAI
   Chat Completions (/v1/chat/completions) custom-provider code paths place
   a moving `cache_control` breakpoint, so prompt caching never advances
   past the system prompt. Fix: inject a single top-level
   `"cache_control": {"type": "ephemeral"}` field into the JSON body before
   forwarding, for Claude models only. This matches Anthropic's documented
   "automatic caching" mode, verified by hand to make `cache_read` grow
   correctly on both endpoints through this specific LiteLLM deployment.

2. Session grouping: Zed/Delta send no session or trace identifier, so every
   turn is logged by LiteLLM as its own one-request "session", making the
   spend logs near-impossible to trawl. Fix: derive a stable session id from
   the request's immutable prefix (model + system prompt + first user
   message) and set it as `x-litellm-session-id` and `x-litellm-trace-id`.
   Every turn of one conversation shares the same prefix, so they group;
   different conversations differ in their first user message, so they don't.
   LiteLLM's documented resolution order (from its source) is
   x-litellm-trace-id, then x-litellm-session-id, then any x-*-session-id
   header -- so these two explicit headers win.

- Never touches or needs the API key: Authorization is forwarded unchanged.
- Only touches Claude-model requests (gated by "model" containing "claude"),
  so other models proxied through the same LiteLLM instance are untouched.
- cache_control injection is skipped if the client already sends its own
  top-level `cache_control`; session-id injection is skipped if the client
  already sends any recognized session/trace header -- so each becomes a
  no-op automatically once Zed/Delta ship a real fix, with nothing to undo.
- Does NOT fix cross-model substitution (a request for one Claude model
  occasionally being served by a different one) -- that's server-side on
  LiteLLM and outside what a client-side proxy can address.
- Streams responses through unmodified, forwarding bytes as soon as they
  arrive, for SSE.
- Retries transient upstream failures (connection errors, 429/5xx/529) with
  short backoff, but only before anything has been sent to the client. Once
  a response is streaming, an upstream failure just closes the connection
  (a truncated stream), since a retry would duplicate output. Client
  disconnects are logged as one line rather than a traceback.

Usage:
  python3 cache_fix_proxy.py [listen_port] [upstream_base_url]
Defaults: 4319, https://litellm.internal.corp.fs.team

Point Delta/Zed's provider base URL at http://127.0.0.1:<listen_port>
instead of the real LiteLLM host, keeping the real API key configured
there as before.
"""
import sys, json, time, hashlib, http.client, http.server, urllib.request, urllib.error, socketserver

LISTEN_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 4319
UPSTREAM = (sys.argv[2] if len(sys.argv) > 2 else "https://litellm.internal.corp.fs.team").rstrip("/")

HOP_BY_HOP = {"connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
              "te", "trailers", "transfer-encoding", "upgrade", "host", "content-length"}

RESP_SKIP = HOP_BY_HOP - {"content-length"}

CACHE_CONTROL_PATHS = ("/v1/messages", "/v1/chat/completions", "/chat/completions", "/messages")

# Upstream timeout per socket operation: connecting, or waiting for the next
# bytes of a response.
UPSTREAM_TIMEOUT = 300
# Total attempts per request, including the first. Backoff is 1s, 2s, 4s
# unless upstream sends a numeric Retry-After; capped at MAX_RETRY_DELAY.
MAX_ATTEMPTS = 4
MAX_RETRY_DELAY = 10.0
# 529 is Anthropic's "overloaded" status, which LiteLLM passes through.
RETRY_STATUSES = {408, 429, 500, 502, 503, 504, 529}
# Errors on the client socket meaning Zed/Delta hung up (cancelled, timed out,
# ...). There is no one left to answer.
CLIENT_GONE = (BrokenPipeError, ConnectionResetError, ConnectionAbortedError)
# Errors from talking to upstream: URLError (an OSError), socket errors,
# timeouts, and http.client protocol errors such as IncompleteRead.
UPSTREAM_ERRORS = (OSError, http.client.HTTPException)

def log(msg):
    sys.stderr.write(f"[cache-fix-proxy] {msg}\n")

def _describe(e):
    """Short one-line description of an upstream failure."""
    if isinstance(e, urllib.error.URLError) and isinstance(e.reason, BaseException):
        e = e.reason
    return f"{type(e).__name__}: {e}" if str(e) else type(e).__name__

def _is_timeout(e):
    return isinstance(e, TimeoutError) or (
        isinstance(e, urllib.error.URLError) and isinstance(e.reason, TimeoutError))

def _retry_delay(attempt, headers=None):
    try:
        delay = float(headers.get("Retry-After"))
    except (AttributeError, TypeError, ValueError):
        delay = 2.0 ** (attempt - 1)
    return min(max(delay, 0.0), MAX_RETRY_DELAY)

def open_upstream(req, label):
    """Send req upstream, retrying transient failures. Retrying is safe only
    because nothing has been sent to the client yet.

    Returns the response; an HTTP error status is returned as the HTTPError,
    which is response-like, so it can be relayed. Raises the last error for
    connection failures that are exhausted or not retryable. Timeouts are not
    retried: each one has already waited UPSTREAM_TIMEOUT."""
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            return urllib.request.urlopen(req, timeout=UPSTREAM_TIMEOUT)
        except urllib.error.HTTPError as e:
            if e.code not in RETRY_STATUSES or attempt == MAX_ATTEMPTS:
                return e
            reason, delay = f"HTTP {e.code}", _retry_delay(attempt, e.headers)
            e.close()
        except UPSTREAM_ERRORS as e:
            if _is_timeout(e) or attempt == MAX_ATTEMPTS:
                raise
            reason, delay = _describe(e), _retry_delay(attempt)
        log(f"{label}: upstream {reason} (attempt {attempt}/{MAX_ATTEMPTS}); retrying in {delay:g}s")
        time.sleep(delay)

# Any header LiteLLM already recognizes as a session/trace id (see its
# litellm_pre_call_utils.py): the two explicit headers, plus the generic
# x-*-session-id fallback pattern. If the client sends any of these, leave
# session handling to it.
def _client_has_session_header(headers):
    for name in headers:
        low = name.lower()
        if low in ("x-litellm-trace-id", "x-litellm-session-id"):
            return True
        if low.startswith("x-") and low.endswith("-session-id"):
            return True
    return False

def _stable_text(x):
    """Flatten a string or a list of content blocks to stable text."""
    if isinstance(x, str):
        return x
    if isinstance(x, list):
        parts = []
        for b in x:
            if isinstance(b, dict) and isinstance(b.get("text"), str):
                parts.append(b["text"])
            elif isinstance(b, str):
                parts.append(b)
        return "\n".join(parts)
    return ""

def compute_session_id(data):
    """Derive a stable id from the immutable prefix of the conversation:
    model + system prompt + first user message. Returns None if there is
    nothing stable to key on."""
    model = str(data.get("model", ""))
    # /v1/messages carries the system prompt in a top-level "system" field;
    # /v1/chat/completions carries it as a leading system-role message.
    messages = data.get("messages")
    if isinstance(data.get("system"), (str, list)):
        sys_text = _stable_text(data.get("system"))
    else:
        sys_text = ""
        if isinstance(messages, list):
            for m in messages:
                if isinstance(m, dict) and m.get("role") == "system":
                    sys_text = _stable_text(m.get("content"))
                    break
    first_user = ""
    if isinstance(messages, list):
        for m in messages:
            if isinstance(m, dict) and m.get("role") == "user":
                first_user = _stable_text(m.get("content"))
                break
    if not sys_text and not first_user:
        return None
    h = hashlib.sha256()
    for part in (model, sys_text, first_user):
        h.update(part.encode("utf-8", "ignore"))
        h.update(b"\x00")
    return "zedproxy-" + h.hexdigest()[:32]

def maybe_inject_cache_control(path, body_bytes):
    if not any(path.endswith(p) or p in path for p in CACHE_CONTROL_PATHS):
        return body_bytes, None
    try:
        data = json.loads(body_bytes)
    except Exception:
        return body_bytes, None
    if not isinstance(data, dict):
        return body_bytes, None
    model = str(data.get("model", ""))
    if "claude" not in model.lower():
        return body_bytes, None
    if "cache_control" in data:
        return body_bytes, "already present, left unchanged"
    data["cache_control"] = {"type": "ephemeral"}
    return json.dumps(data).encode(), f"injected for model={model!r}"

def maybe_session_id(path, body_bytes, client_has_header):
    """Return a session id to inject as headers, or None. Reuses the already
    cache-control-processed body bytes to read the request fields."""
    if client_has_header:
        return None
    if not any(path.endswith(p) or p in path for p in CACHE_CONTROL_PATHS):
        return None
    try:
        data = json.loads(body_bytes)
    except Exception:
        return None
    if not isinstance(data, dict):
        return None
    if "claude" not in str(data.get("model", "")).lower():
        return None
    return compute_session_id(data)

class Handler(http.server.BaseHTTPRequestHandler):
    # HTTP/1.0: every response closes the connection, so there is no
    # keep-alive ambiguity to get wrong. (Bug found in testing: HTTP/1.1
    # plus stripping Content-Length as a "hop-by-hop" header on the
    # response left clients with no way to detect end-of-body, hanging
    # on the next request.)
    protocol_version = "HTTP/1.0"

    def _proxy(self, method):
        label = f"{method} {self.path}"
        try:
            self._proxy_request(method, label)
        except CLIENT_GONE as e:
            # Only client-socket I/O can raise these here: _proxy_request
            # handles every upstream error itself.
            log(f"{label}: client disconnected ({type(e).__name__}); response dropped")
            self.close_connection = True

    def _proxy_request(self, method, label):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else b""

        note = None
        session_id = None
        if method == "POST" and body:
            body, note = maybe_inject_cache_control(self.path, body)
            session_id = maybe_session_id(
                self.path, body, _client_has_session_header(self.headers)
            )
        sess_note = f"session={session_id}" if session_id else "session=client/none"
        log(f"{label} -> {note or 'no cache change'}; {sess_note}")

        headers = {k: v for k, v in self.headers.items() if k.lower() not in HOP_BY_HOP}
        if session_id:
            headers["x-litellm-session-id"] = session_id
            headers["x-litellm-trace-id"] = session_id
        req = urllib.request.Request(UPSTREAM + self.path, data=body if body else None,
                                      headers=headers, method=method)
        try:
            resp = open_upstream(req, label)
        except UPSTREAM_ERRORS as e:
            if _is_timeout(e):
                log(f"{label}: upstream timed out")
                self._send_plain(504, "upstream timed out")
            else:
                log(f"{label}: upstream failed: {_describe(e)}")
                self._send_plain(502, f"upstream error: {_describe(e)}")
            return
        with resp:
            if isinstance(resp, urllib.error.HTTPError):
                log(f"{label}: upstream HTTP {resp.code}, passed through")
            self._relay(resp, label)

    def _relay(self, resp, label):
        """Send upstream's status and headers, then stream its body as bytes
        arrive. After the status line is out, an upstream failure can't become
        an error response: writing one would put a second status line inside
        the body. Closing early, leaving a truncated stream, is the only clean
        signal."""
        self.send_response(resp.status)
        for k, v in resp.headers.items():
            if k.lower() not in RESP_SKIP:
                self.send_header(k, v)
        self.send_header("Connection", "close")
        self.end_headers()
        sent = 0
        while True:
            try:
                # read1, not read: on a chunked response read(n) blocks until
                # n bytes accumulate, which holds SSE events back.
                chunk = resp.read1(65536)
            except UPSTREAM_ERRORS as e:
                log(f"{label}: upstream failed mid-stream after {sent} bytes "
                    f"({_describe(e)}); closing client connection")
                return
            if not chunk:
                return
            self.wfile.write(chunk)
            self.wfile.flush()
            sent += len(chunk)

    def _send_plain(self, status, text):
        body = f"cache-fix-proxy: {text}\n".encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self): self._proxy("GET")
    def do_POST(self): self._proxy("POST")
    def log_message(self, fmt, *args): pass

class ThreadingServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

if __name__ == "__main__":
    srv = ThreadingServer(("127.0.0.1", LISTEN_PORT), Handler)
    sys.stderr.write(f"[cache-fix-proxy] listening on http://127.0.0.1:{LISTEN_PORT} -> {UPSTREAM}\n")
    srv.serve_forever()
