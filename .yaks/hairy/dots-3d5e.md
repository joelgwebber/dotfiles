---
id: dots-3d5e
title: noctalia-greeter floods journal at 60 msg/s
type: bug
priority: 1
created: '2026-09-24T03:01:49Z'
updated: '2026-09-24T03:03:15Z'
parent: dots-df8e
labels:
- linux
needs: human
---

---
▸ 2026-09-24T03:03:04Z [claude]
Root-caused. 92012/92034 msgs = one wlroots line at exactly 60/s: 'types/output/output.c:1013 Direct scan-out disabled by software cursor'. greetd up 09:13:00, compositor exited 16:02:15 => 6h49m => ~1.47M lines/session. The documented knob is DEAD: noctalia-greeter-session exports WLR_LOG=error but 'strings noctalia-greeter-compositor | grep -c WLR_LOG' = 0, and the single wlr_log_init call site has verbosity hardcoded (mov $0x2,%edi = WLR_INFO). Upstream bug. Workaround = per-unit journald rate limit on greetd.service. Also NOCTALIA_GREETER_IDLE_TIMEOUT is read by the binary and unexplored.

---
▸ 2026-09-24T03:03:15Z [claude]
Needs sudo: 'systemctl edit greetd.service' to add LogRateLimitIntervalSec=30s / LogRateLimitBurst=200. Open question for you: also file the WLR_LOG-is-ignored bug upstream against noctalia-greeter 1.5.0?
