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
- Streams responses through unmodified, chunk by chunk, for SSE.

Usage:
  python3 cache_fix_proxy.py [listen_port] [upstream_base_url]
Defaults: 4319, https://litellm.internal.corp.fs.team

Point Delta/Zed's provider base URL at http://127.0.0.1:<listen_port>
instead of the real LiteLLM host, keeping the real API key configured
there as before.
"""
import sys, json, hashlib, http.server, urllib.request, urllib.error, socketserver

LISTEN_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 4319
UPSTREAM = (sys.argv[2] if len(sys.argv) > 2 else "https://litellm.internal.corp.fs.team").rstrip("/")

HOP_BY_HOP = {"connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
              "te", "trailers", "transfer-encoding", "upgrade", "host", "content-length"}

CACHE_CONTROL_PATHS = ("/v1/messages", "/v1/chat/completions", "/chat/completions", "/messages")

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
        sys.stderr.write(
            f"[cache-fix-proxy] {method} {self.path} -> {note or 'no cache change'}; {sess_note}\n"
        )

        headers = {k: v for k, v in self.headers.items() if k.lower() not in HOP_BY_HOP}
        if session_id:
            headers["x-litellm-session-id"] = session_id
            headers["x-litellm-trace-id"] = session_id
        req = urllib.request.Request(UPSTREAM + self.path, data=body if body else None,
                                      headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=300) as resp:
                self.send_response(resp.status)
                resp_skip = HOP_BY_HOP - {"content-length"}
                for k, v in resp.getheaders():
                    if k.lower() not in resp_skip:
                        self.send_header(k, v)
                self.send_header("Connection", "close")
                self.end_headers()
                while True:
                    chunk = resp.read(8192)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    self.wfile.flush()
        except TimeoutError:
            self.send_response(504)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(b"cache-fix-proxy: upstream timed out\n")
        except urllib.error.HTTPError as e:
            body_err = e.read()
            self.send_response(e.code)
            resp_skip = HOP_BY_HOP - {"content-length"}
            for k, v in e.headers.items():
                if k.lower() not in resp_skip:
                    self.send_header(k, v)
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(body_err)
        except urllib.error.URLError as e:
            self.send_response(502)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(f"cache-fix-proxy: upstream error: {e}\n".encode())
        except Exception as e:
            self.send_response(500)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(f"cache-fix-proxy: proxy error: {e}\n".encode())

    def do_GET(self): self._proxy("GET")
    def do_POST(self): self._proxy("POST")
    def log_message(self, fmt, *args): pass

class ThreadingServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

if __name__ == "__main__":
    srv = ThreadingServer(("127.0.0.1", LISTEN_PORT), Handler)
    sys.stderr.write(f"[cache-fix-proxy] listening on http://127.0.0.1:{LISTEN_PORT} -> {UPSTREAM}\n")
    srv.serve_forever()
