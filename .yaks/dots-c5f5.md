---
id: dots-c5f5
title: Make litellm-proxy stream SSE live, retry transient upstream errors, and handle client disconnects
status: shorn
type: bug
priority: 1
created: '2026-10-17T03:18:53Z'
updated: '2026-10-17T03:19:04Z'
labels:
- litellm-proxy
---

Joel saw BrokenPipeError tracebacks from bin/litellm-proxy.py and the agent harness misbehaving.

Reproduced against a fake chunked-SSE upstream:
- resp.read(8192) on a chunked response blocks until 8 KB accumulate, so SSE events reached the client in bursts (5 events 0.5s apart all arrived at 2.5s).
- Any failure after headers were sent fell into the error handlers, which wrote a second HTTP status line + text/plain body into the middle of the SSE stream (and dropped buffered events). With a client hangup this produced the double BrokenPipe traceback from the logs.

Fix: stream with read1; retry transient upstream failures (connection errors, 408/429/500/502/503/504/529; 1s/2s/4s or Retry-After, capped 10s; 4 attempts) only before anything is sent to the client; after streaming starts, an upstream failure just closes the connection; client disconnects log one line.

---
▸ 2026-10-17T03:18:53Z [Delta agent]
moved: hairy -> shaving

---
▸ 2026-10-17T03:19:04Z [Delta agent]
Verified with a fake chunked-SSE upstream: events now arrive at 0.5s intervals; mid-stream upstream failure truncates cleanly (no injected status line); 529x2 retried then streamed; 400 passed through without retry; RemoteDisconnected and connection-refused retried 3x then 502 after 7s; client hangup logs one line and closes upstream. Follow-up: dots-a234.

---
▸ 2026-10-17T03:19:04Z [Delta agent]
moved: shaving -> shorn
