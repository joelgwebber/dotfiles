---
id: dots-df8e
title: Diagnose idle hard-locks on j15r
type: task
priority: 1
created: '2026-09-24T02:59:30Z'
updated: '2026-09-27T20:27:44Z'
labels:
- linux
---

---
▸ 2026-09-24T03:04:38Z [claude]
Investigation phase complete; findings in docs/idle-hardlock-notes.md. All four remediation children blocked on sudo/physical access (yaks inbox). Leaving parent shaving until they land. Incidental blocker found and filed: dots-2c1b (macOS credential helper in ~/.gitconfig broke the push).

---
▸ 2026-09-27T17:47:10Z [claude]
BREAKTHROUGH - the 4G journal retention paid off immediately. Six boots now retained (Sep 23 -> Sep 27) and two of them are captured hard hangs.

Boot -3: 2026-09-24 08:27:33 -> 21:33:01 (13h06m). Boot -2: 2026-09-26 11:43:53 -> 18:03:23 (6h20m). Both end mid-line in the greeter flood with NO shutdown sequence. Boot -4 by contrast has real shutdown markers = clean.

THE CORRELATION: the two hung boots are exactly the two boots where nobody ever logged in - 'greeter exited with status' never appears, and the original boot-time compositor (PID 1048 / 1042) is still the last thing logging. The two boots that ended cleanly or are still alive (-4, 0) both started a niri session and the greeter exited normally. 2-for-2: hangs happen at the noctalia greeter, not in a niri session.

Caveat: n=2, and 'never logged in' is confounded with 'nobody touched the machine'. A logged-in-but-idle-for-13h boot that survives would break the tie; we have no such sample (-4 was logged in but only 4h before a clean shutdown).

Also ruled out for both hangs: zero Xid / NVRM / GPU-hang / GPU-reset messages, zero MCE or thermal events, no AER. Nothing was reported before either cut.

Incidental: niri logged 'vblank_throttle: output DP-1 running faster than expected, expected refresh 13.337065ms, got vblank after 6.658ms' (75Hz expected, 150Hz seen) - second sign of display-pipeline oddity on this setup, not a hang cause.

This elevates dots-3d5e from log-noise cleanup to a possible cause.

---
▸ 2026-09-27T20:27:44Z [claude]
STATUS Sep 27 16:25 - the hypothesis is NOT yet tested. Do not read the absence of hangs as success.

Exposure since the fixes landed (~13:33 today), across three boots:
  boot -2  13:05:57 -> 14:35:40  1h30m  clean shutdown, niri session
  boot -1  14:36:08 -> 14:49:22  13m    clean shutdown, niri session
  boot  0  16:10:17 -> running   ~15m   niri session
Total ~1h58m. The 81-minute gap between -1 and 0 was a deliberate power-off (4 shutdown markers on -1), not a hang.

Compare the observed times-to-hang: 13h06m (boot -5) and 6h20m (boot -4). The longest post-fix run is 1h30m = under a quarter of the SHORTER of the two. And more importantly, all three post-fix boots were logged into niri with the greeter exited within minutes - i.e. never in the condition under which the machine actually died (sitting at the greeter, never logged in). So we have zero exposure to the trigger, not a passing test.

What a real test looks like: leave it at the greeter (or logged-in-idle) for 13h+ and see. If it survives that twice, the fixes or pcie_aspm=off mean something. Until then the only thing genuinely settled is that a hang would now be CAPTURED (dots-d532 shorn: pstore live, hardlockup_panic=1, panic=20).

RED HERRING ruled out: 'clocksource: Watchdog remote CPU N read timed out' occurs exactly once per substantial boot on a random CPU (9, 25, 12, 27, 5, 13 across boots -6,-5,-4,-2,-1,0). It appears in cleanly-shut-down boots just as often as in the two hang boots, never escalated, never marked TSC unstable, and the clocksource stayed tsc throughout. It does not discriminate hangs - not a predictor.

Still clean since the fixes: no lockup/panic events, no Xid/NVRM, no MCE, no thermal, and all PCIe AER counters still zero even with pcie_aspm=off now active.
