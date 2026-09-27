---
id: dots-d532
title: Enable a post-mortem capture path for hard locks
type: task
priority: 2
created: '2026-09-24T03:01:49Z'
updated: '2026-09-27T20:56:28Z'
parent: dots-df8e
labels:
- linux
verify: journalctl -b -k | grep -q 'Registered efi_pstore as persistent store backend' && test "$(sysctl -n kernel.nmi_watchdog)" = 1 && test "$(sysctl -n kernel.hardlockup_panic)" = 1 && test "$(sysctl -n kernel.panic)" = 20
---

---
▸ 2026-09-24T03:03:04Z [claude]
Nothing can currently record a hard lock: nmi_watchdog=0, watchdog=0, hardlockup_panic=0, panic=0, panic_on_oops=0, no /dev/watchdog. All because 'nowatchdog' is on the cmdline - which disables the very NMI hard-lockup detector that would catch this. Kernel HAS the machinery: CONFIG_HARDLOCKUP_DETECTOR{,_PERF}=y, CONFIG_EFI_VARS_PSTORE=y (default-disabled, needs efi_pstore.pstore_disable=0), CONFIG_PSTORE_RAM=m, CONFIG_NETCONSOLE=m. No ACPI ERST/BERT tables.

---
▸ 2026-09-24T03:03:15Z [claude]
Needs sudo + a reboot: drop 'nowatchdog' (and probably 'quiet') from KERNEL_CMDLINE in /etc/default/limine, add efi_pstore.pstore_disable=0, run limine-update, add /etc/sysctl.d/99-lockup.conf. Decision for you: EFI-NVRAM pstore vs ramoops vs netconsole.

---
▸ 2026-09-24T03:23:08Z [claude]
sysctl.d precedence checked against sysctl.d(5): all files across /etc, /run, /usr/local/lib, /usr/lib are sorted together by BASENAME, lexicographically-latest wins; directory priority only applies to same-name files (full masking). No /etc/sysctl.conf on this box. Recommended bands: 10-40 for /usr, 60-90 for /etc.

SECOND KILL SWITCH FOUND: /usr/lib/sysctl.d/70-cachyos-settings.conf:30 already sets 'kernel.nmi_watchdog = 0' (comment cites perf/power). So removing 'nowatchdog' from the cmdline alone is NOT enough - that file re-disables it every boot. Needs an /etc/sysctl.d file sorting after 70-.

THIRD ONE: same file sets 'kernel.printk = 3 3 3 3' to hide kernel messages from the console - that would hide a panic too, on top of 'quiet'. Want 7 4 1 7 while diagnosing.

Drafted /etc/sysctl.d/90-lockup-diag.conf (in session scratchpad, not yet installed - needs sudo).

![90-lockup-diag](artifacts/dots-d532/90-lockup-diag.conf)

---
▸ 2026-09-27T17:32:52Z [claude]
Regenerated (the scratchpad copy was cleaned). Attaching so it lives in the repo instead of /tmp. Install with: sudo install -m644 -o root -g root .yaks/artifacts/dots-d532/90-lockup-diag.conf /etc/sysctl.d/ && sudo sysctl --system

---
▸ 2026-09-27T17:33:00Z [claude]
State check 2026-09-27: cmdline is now 'splash rw rootflags=subvol=/@ root=UUID=... nvme_core.default_ps_max_latency_us=0 pcie_aspm=off' -- joel removed 'quiet' and 'nowatchdog' and added pcie_aspm=off.

Second-kill-switch prediction CONFIRMED empirically: kernel.watchdog flipped 0 -> 1 (softlockup detector now live), but kernel.nmi_watchdog is STILL 0 and kernel.printk is STILL '3 3 3 3', because 70-cachyos-settings.conf re-pins both every boot. /etc/sysctl.d/ is empty, so the override was never installed. The attached 90-lockup-diag.conf is now the only remaining blocker for hard-lockup detection.

Also still missing: efi_pstore.pstore_disable=0 on the cmdline, so a panic has nowhere to land across a reboot. kernel.panic is still 0 (no auto-reboot).

---
▸ 2026-09-27T17:47:10Z [claude]
Install verified 2026-09-27. All targets correct: nmi_watchdog=1, watchdog=1, soft_watchdog=1, hardlockup_panic=1, softlockup_panic=1, panic=20, panic_on_oops=1, printk=7 4 1 7. Kernel confirms the hard-lockup detector actually initialised on the AMD PMU: 'NMI watchdog: Enabled. Permanently consumes one hw-PMU counter.' (perf-based init was the open risk; it did not fail.)

printk showing '7 4 1 7' is the intended value from this file, not an anomaly - it countermands the CachyOS '3 3 3 3'.

REMAINING GAP: no pstore backing. efi_pstore.pstore_disable=0 is still absent from the cmdline, so the next panic will auto-reboot (panic=20) but leave no record across the reboot. That is now the single highest-value thing left, because hardlockup_panic=1 means the next hang is the first one that CAN be captured.

![add-pstore-cmdline](artifacts/dots-d532/add-pstore-cmdline.sh)

---
▸ 2026-09-27T18:08:11Z [claude]
Ready-to-run script to add efi_pstore.pstore_disable=0 to KERNEL_CMDLINE[default] and run limine-update. Backs up /etc/default/limine first, verifies the edit applied (restores on failure), prints a diff, then regenerates entries. Guarded by a grep so re-running is a no-op. Adds ONLY the pstore flag so the in-flight pcie_aspm=off experiment is not disturbed. sed verified against a copy of the real file - produces the intended line exactly.

---
▸ 2026-09-27T20:27:08Z [claude]
Done. Capture path is fully live and survives reboot: 'nowatchdog'/'quiet' off the cmdline, efi_pstore.pstore_disable=0 added, and boot 0 (Sep 27 16:10:17) logs both 'NMI watchdog: Enabled. Permanently consumes one hw-PMU counter.' and 'pstore: Registered efi_pstore as persistent store backend'. Sysctls confirmed after reboot: nmi_watchdog=1, hardlockup_panic=1, panic=20, printk=7 4 1 7. The next hard lock should now panic, auto-reboot after 20s, and leave a record in /sys/fs/pstore.

---
▸ 2026-09-27T20:27:08Z [Joel Webber]
verify: `journalctl -b -k | grep -q 'Registered efi_pstore as persistent store backend' && test "$(sysctl -n kernel.nmi_watchdog)" = 1 && test "$(sysctl -n kernel.hardlockup_panic)" = 1 && test "$(sysctl -n kernel.panic)" = 20` -> PASS (exit 0)

---
▸ 2026-09-27T20:56:28Z [claude]
REOPENED. I sheared this on the evidence that efi_pstore registered, but the first real hang shows the capture path is incomplete in two ways:

1. systemd-pstore.service is DISABLED (loaded, inactive, preset: enabled). Nothing archives /sys/fs/pstore into /var/lib/systemd/pstore, which is empty. Records also stay in EFI NVRAM instead of being drained to disk.
2. /sys/fs/pstore is root-only, so the record - if any - cannot be read without sudo. I cannot confirm whether the Sep 27 16:25:39 hang left one.

Also: the detector WAS armed during the hung boot. Boot -1 logged 'NMI watchdog: Enabled. Permanently consumes one hw-PMU counter.' and 'pstore: Registered efi_pstore as persistent store backend' at 16:10:17. It still did not recover: the gap from last log (16:25:39) to next boot (16:31:49) is 6m10s, not the ~20s that kernel.panic=20 would produce, which points to a manual power cycle rather than a panic-and-reboot.

TODO: (a) sudo ls -la /sys/fs/pstore/ and read any record - EFI records persist so it should still be there; (b) systemctl enable --now systemd-pstore.service so future records are archived readably and drained out of NVRAM.
