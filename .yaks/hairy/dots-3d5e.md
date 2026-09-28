---
id: dots-3d5e
title: noctalia-greeter floods journal at 60 msg/s
type: bug
priority: 1
created: '2026-09-24T03:01:49Z'
updated: '2026-09-28T12:22:27Z'
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

---
▸ 2026-09-27T17:47:10Z [claude]
Raised priority context: per dots-df8e, both captured hard hangs happened while this compositor was the only thing running, and neither logged-in boot hung. The 60fps spin is no longer just a log-volume problem - it is the prime suspect's environment. NOCTALIA_GREETER_IDLE_TIMEOUT (read by the binary, unexplored) is now the interesting lever: if it parks the compositor it changes exactly the condition under which the machine dies.

---
▸ 2026-09-27T20:27:21Z [claude]
Still open as of Sep 27 16:25 - no greetd.service rate-limit drop-in installed. Note the flood rate is unchanged; boot 0 shows only 398 lines purely because joel logged in within ~7s of the greeter starting. Boots -2 and -1 logged 41106 and 45900 lines respectively. This is now the last untested variable in dots-df8e: every post-fix boot has been short and logged-in, i.e. never in the condition under which the machine actually died.

---
▸ 2026-09-28T12:22:27Z [claude]
EXONERATED as a hang suspect. Hang #4 happened in a logged-in idle niri session with the greeter long exited, and hang #3 under load - so hangs occur with or without this compositor running. See the state table on dots-df8e. This reverts to what it originally was: a real log-volume bug (77227 lines in boot -1, ~21 minutes at the greeter) with a broken WLR_LOG knob, worth fixing for tidiness at p3-ish urgency, not for stability.
