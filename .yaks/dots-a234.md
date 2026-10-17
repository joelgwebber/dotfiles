---
id: dots-a234
title: Confirm harness disconnects stop after litellm-proxy streaming fix
status: hairy
type: task
priority: 2
created: '2026-10-17T03:18:59Z'
updated: '2026-10-17T03:18:59Z'
labels:
- litellm-proxy
---

dots-c5f5 fixed the proxy's SSE buffering and stream corruption, but the BrokenPipeErrors in Joel's logs mean Zed/Delta hung up first, and why is not proven. Leading hypothesis: 8 KB buffering starved the client long enough to trip an idle timeout or a user cancel.

After running the fixed proxy for a while, grep its stderr for "client disconnected". If they still happen often, look at the harness's stream timeouts.

Minor, seen while testing: responses carry duplicate Server/Date headers (the proxy's own send_response adds them, plus upstream's). Harmless so far; skip forwarding those two if it ever matters.
