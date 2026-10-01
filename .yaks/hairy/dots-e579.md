---
id: dots-e579
title: Revisit the C-state workaround on j15r (processor.max_cstate=1)
type: task
priority: 3
created: '2026-10-01T02:26:40Z'
updated: '2026-10-01T02:27:10Z'
labels:
- linux
verify: grep -q processor.max_cstate=1 /proc/cmdline
---

The idle hard-locks on j15r (dots-df8e, six hangs between 2026-09-23 and 2026-09-29) are worked around by processor.max_cstate=1 on the kernel cmdline, which keeps the package out of deep idle (PC6). It costs about 12 W at idle and 2 C. This yak is the reminder that it is a WORKAROUND, not a fix, and that it should be retested periodically rather than carried forever.

---
▸ 2026-10-01T02:27:10Z [Joel Webber]
Successor to dots-df8e, which is shorn: the diagnosis is done and the workaround is deployed and confirmed. This yak holds only what is still genuinely open.

THE STATE OF THINGS (verified boot 0, 2026-09-30 22:12)
  /proc/cmdline: splash rw rootflags=subvol=/@ root=UUID=8967db38-... efi_pstore.pstore_disable=0 processor.max_cstate=1
  /sys/devices/system/cpu/cpu0/cpuidle/ now contains ONLY state0 (POLL) and state1 (C1).
  state2 is GONE, not merely disabled - max_cstate=1 stops acpi_idle registering it at all, which is a stronger guarantee than the sysfs toggle it replaces.
  Preceding boot -1 ran 24h53m09s and hang-watch classified it CLEAN: the longest run in the entire recorded history, and 1.9x the longest pre-fix time-to-hang (13h06m).

WHAT IS ACTUALLY UNCERTAIN
  Confidence is roughly 97%, not 100%. Six hangs over ~45h of pre-fix uptime puts MTTF near 7h, so a 24h survival is about exp(-24/7) ~ 3% likely by chance. Strong, but one clean run.
  The cmdline edit also REMOVED pcie_aspm=off and nvme_core.default_ps_max_latency_us=0 in the same reboot, so three variables changed at once. Both removed flags were already falsified individually (hangs occurred with each active), so the risk is attributional rather than real - but if a hang does recur, that ambiguity has to be resolved before concluding max_cstate=1 is insufficient.

OPEN ITEM 1 - decide whether to pay for certainty, once.
  Re-enable C2 (echo 0 | sudo tee /sys/devices/system/cpu/cpu*/cpuidle/state2/disable will NOT work now that max_cstate=1 removes the state; it needs the cmdline flag taken back off plus a reboot) and leave it idle. A hang inside ~13h converts 97% into known. Cost: one hang, now survivable because the watchdog is finally armed and will reboot it in 60s instead of it sitting dead overnight. Worth doing once rather than carrying a permanent 12 W penalty on a maybe.

OPEN ITEM 2 - retest after a future AGESA.
  Root cause is most likely SoC/AGESA behaviour around package C6 on this 5950X + MSI MS-7D53 + 4x32GB combination. Already on the newest BIOS (1.D4, AGESA 1.2.0.12), so there is nothing to apply today. When MSI ships a newer AGESA: flash it, drop max_cstate=1, and leave the machine idle for several days. That is the only path to removing the workaround rather than living with it.
  Also unexplored and narrower than max_cstate=1: AMD CBS has per-feature knobs (Global C-state Control, and on some boards a package-C6 specific option). Disabling PC6 alone while keeping core CC6 would recover most of the 12 W. Worth a look in setup on the next BIOS trip.

OPEN ITEM 3 - the cost, measured.
  cstate-cost A/B (back to back, same ambient): 39.9 W / Tctl 35.1 C with C2 disabled vs 27.6 W / Tctl 32.9 C with C2 enabled. So about +12 W and +2 C at idle, continuous. Script lives at .yaks/artifacts/dots-df8e/cstate-cost; it toggles state2, which no longer exists under max_cstate=1, so re-running it means taking the cmdline flag off first.
  Genuine upside worth remembering before optimising this away: losing the ~18us C2 exit latency improves interactive, audio and network latency determinism.

OPEN ITEM 4 - only if hangs recur.
  Inherited from dots-dfbf (shorn): memtest86+ passed twice, so bad DIMM cells are cleared, but memory UNDER CONTENTION never was - the 9.5h stress-ng --vm 32 run used the 256 MB default and was effectively a CPU/cache soak. A real test is stress-ng --vm 32 --vm-bytes 90% --verify. Also still on auto and unconfirmed: FCLK/UCLK ratios and SoC voltages with 4x32GB, which ran the whole investigation at the JEDEC 2133/1.2V fallback after the flash reset defaults.
  Also never checked: the 12VHPWR connector seating on the 4090, and PSU regulation at very low draw. Both predict exactly "fails at idle, survives load", same as PC6 did - so if max_cstate=1 turns out insufficient, these are next, not the memory.

WATCHDOG AMBIGUITY, carried from dots-d532.
  With sp5100_tco finally armed, a spurious watchdog reset and a real hang look identical in hang-watch: both print HANG ... sat dead ~Ns. CachyOS deny-lists this module deliberately and it has a history of spurious resets on some boards. A reset whose dead time is near the 60s timeout, with no other symptom, means suspect the watchdog before reopening the hang investigation.

FULL NARRATIVE lives in docs/idle-hardlock-notes.md. Hang-by-hang forensics stay in .yaks/shorn/dots-df8e.md.
