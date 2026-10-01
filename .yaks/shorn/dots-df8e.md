---
id: dots-df8e
title: Diagnose idle hard-locks on j15r
type: task
priority: 1
created: '2026-09-24T02:59:30Z'
updated: '2026-10-01T02:27:48Z'
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

---
▸ 2026-09-27T20:56:28Z [claude]
HANG #3, and it breaks the greeter hypothesis.

Boot -1: 16:10:17 -> 16:25:39, only 15m22s of uptime. Ended abruptly mid-line ('Started app-niri-alacritty-52071.scope'), no shutdown sequence. Unclean shutdown independently confirmed on the next boot: 'systemd-journald: File .../system.journal corrupted or uncleanly shut down, renaming and replacing.'

WHY THIS BREAKS THE HYPOTHESIS: this one happened while LOGGED IN to niri and under real load - not at the greeter. An alacritty scope reported 34min 2.263s CPU over 9min 43.079s wall clock, 6.4G memory peak at 16:21:05 (that was almost certainly my own journalctl scanning of the 1.8G journal set during the previous session). Profile is the opposite of the first two hangs: 15 minutes vs 6h20m/13h06m, active vs idle, in-session vs at-greeter.

So either there are two distinct failure modes, or the 2-for-2 greeter correlation was coincidence. Either way the greeter is no longer the leading suspect on its own. Recorded as a correction to the earlier note.

pcie_aspm=off IS FALSIFIED as a fix: it was active on the cmdline for this boot and the machine hung anyway. It costs idle power for no demonstrated benefit - reasonable to drop now.

NMI HARD-LOCKUP DETECTOR DID NOT FIRE despite being armed. A CPU spinning with interrupts disabled would be caught by the perf-NMI watchdog; it wasn't, and there were NO kernel messages at all in the final 10 minutes. That points away from a simple CPU lockup and toward something that halts the whole platform including NMI delivery - firmware/SMI freeze or a bus-level wedge. Caveat: cannot yet distinguish 'never fired' from 'fired but could not write or reboot' - only /sys/fs/pstore settles that (see dots-d532).

Ruled out again for this hang: no Xid/NVRM, no MCE, no thermal, no AER, no OOM (0 across all boots; 125Gi RAM, 6.4G peak is nothing).

This promotes dots-c1e2 (BIOS 1.40 from 2022 + Power Supply Idle Control) to the top remaining lever.

---
▸ 2026-09-27T22:05:15Z [claude]
NEW BASELINE Sep 27 17:55. BIOS 1.40 (AGESA 1.2.0.7, 2022) -> 1.D4 (AGESA 1.2.0.12, 2026), microcode 0x0a20102e -> 0x0a201030. dots-c1e2 shorn. This resets the observation window: every prior hang was on 4-year-old firmware, so the hang history is no longer directly comparable.

EVIDENCE LOSS: the BIOS flash cleared EFI NVRAM, which is where efi_pstore records live. If hang #3 (Sep 27 16:25:39) left a record, it is gone - we never read it, because /sys/fs/pstore needs root and systemd-pstore.service was disabled at the time. That specific post-mortem is unrecoverable. systemd-pstore.service is now 'enabled', so future records will be archived to /var/lib/systemd/pstore (currently empty) instead of only sitting in NVRAM.

WHAT A MEANINGFUL TEST LOOKS LIKE NOW: the two idle hangs took 13h06m and 6h20m, and hang #3 took 15m under load. So a credible 'fixed' signal needs multiple multi-hour runs, including at least one long idle stretch, not just a quiet evening. Current uptime is minutes.

pcie_aspm=off is still on the cmdline despite being falsified by hang #3. Recommend leaving it for one observation period so the BIOS is the only changed variable, then dropping it - the new BIOS is the first one to expose PCIe ASPM Control in setup (added in v17), so the platform's own handling now has 4 years of fixes behind it.

---
▸ 2026-09-27T22:30:51Z [claude]
New child dots-dfbf: 4x32GB at XMP as a candidate root cause. Raised because the post-flash dmidecode shows all four DIMMs fell back to JEDEC 2133 / 1.2 V. Two consequences: (1) memory instability on a 4-DIMM AM4 config fits the no-logs/no-MCE/no-NMI signature better than anything else considered so far, including the greeter; (2) the observation window starting now is confounded - it is 'new BIOS AND underclocked memory', not 'new BIOS'. Recommended re-enabling A-XMP in the same BIOS trip as Power Supply Idle Control to keep it a single variable.

---
▸ 2026-09-28T00:01:51Z [claude]
Post-BIOS-settings state, Sep 27 19:30 boot: BIOS 1.D4, Power Supply Idle Control set to Typical Current Idle (not verifiable from the OS - it affects VRM idle current, not the exposed ACPI C-states; cpuidle shows POLL/C1/C2 under acpi_idle, and I have no pre-change baseline to compare anyway). limine-install ran - 'Boot0000* Limine' is restored and the USB stick entry is gone. Both reboots clean, no unclean-shutdown markers. Minor: BootOrder is 0001,0000 so the fallback still boots first; harmless since both point at Limine on the same ESP, but 'sudo efibootmgr -o 0000,0001' would put the named entry first.

Uptime 30m. Nothing proven yet - see the calibration note above (13h06m / 6h20m / 15m-under-load).

---
▸ 2026-09-28T12:22:06Z [claude]
HANG #4. Boot -1: Sep 27 19:30:26 -> 21:41:37 = 2h11m11s. Ends abruptly on 'snapperd.service: Deactivated successfully' with no shutdown sequence. It sat dead from 21:41 until joel powered it on at 08:12 next morning (10.5h), so panic=20 did NOT auto-reboot it - i.e. no panic.

THE BIOS UPDATE DID NOT FIX IT. Hang #4 ran on BIOS 1.D4 (AGESA 1.2.0.12, microcode 0x0a201030) WITH Power Supply Idle Control set to Typical Current Idle. Both are now eliminated as complete explanations.

THE GREETER HYPOTHESIS IS DEFINITIVELY DEAD. Full state table:
  #1 Sep 24 08:27:33->21:33:01  13h06m  at greeter, never logged in
  #2 Sep 26 11:43:53->18:03:23   6h20m  at greeter, never logged in
  #3 Sep 27 16:10:17->16:25:39  15m22s  logged in, heavy load
  #4 Sep 27 19:30:26->21:41:37   2h11m  logged in, IDLE (greeter exited, niri session up)
Hangs now observed in all three states - at greeter, logged-in-idle, and logged-in-under-load. No software state correlates. Times-to-hang 13h06m/6h20m/15m/2h11m show no pattern.

PSTORE HAS NOW FAILED TWICE. Hangs #3 and #4 both ran with the NMI watchdog armed and efi_pstore registered (verified in each boot's log). /sys/fs/pstore was EMPTY at next boot both times - systemd-pstore.service logged 'skipped, unmet condition check ConditionDirectoryNotEmpty=/sys/fs/pstore'. No kernel messages in the final 20 minutes of #4 either. Conclusion: the kernel never gets a chance to panic. This is not a CPU lockup the kernel can observe; it is a platform-level freeze.

Note on evidence: boot 0 shows NO journald corruption or btrfs replay this time (unlike #3). That does not mean a clean shutdown - btrfs is CoW and nothing was writing at 21:41, so the tree was already consistent. The abrupt log end with no shutdown sequence is the reliable signal.

ELIMINATED: nvme_core.default_ps_max_latency_us=0, pcie_aspm=off, BIOS 1.40->1.D4, Power Supply Idle Control, the greeter/compositor, aggressive memory speed (it hangs at JEDEC 2133/1.2V fallback), thermal (Tctl 44C idle, no thermal events ever), OOM (zero ever), GPU (no Xid/NVRM in any hang), MCE (none), PCIe AER (all counters zero).

STILL STANDING: a faulty DIMM or an IMC marginal at any speed (dots-dfbf, untested); power delivery / PSU, which fits a zero-log freeze in both idle and load, and 5950X + RTX 4090 is a brutal transient load; motherboard VRM. Worth asking joel what PSU this is - model, wattage, age - since nothing in the OS can see it.

---
▸ 2026-09-29T12:21:11Z [claude]
STATUS 2026-09-29. No hang since #5 (Sep 27 21:41:37) - hang-watch reports boots -7..-1 all CLEAN. But exposure is thin again: those seven boots ran 42m, 1h00m, 28s, 7m, 5m, 57m, 8m - about 3h20m total, longest 1h00m, against hangs that took 15m to 13h06m. Not evidence of a fix.

Good news: watchdog is now genuinely armed (RuntimeWatchdogUSec=1min), hang-watch is installed and working, and Secure Boot is back off.

memtest86+ passed twice - see dots-dfbf. Memory integrity largely cleared; memory-under-load is not.

REMAINING CANDIDATES, ranked by fit x cost:

1. 12VHPWR / GPU POWER CONNECTOR. Intermittent contact on a 4090's 12VHPWR is a well-known failure, and momentary power loss to the GPU wedges the whole machine instantly with no time to log anything - which matches all five hangs, idle and load alike. Free to inspect while the case is open for the PSU. Higher risk if a 3x8-pin -> 12VHPWR adapter is in use rather than a native cable.

2. PSU TRANSIENT RESPONSE, not wattage. 'Well above the combined needs' does not cover this: a 4090 draws sub-millisecond transients around twice its TDP, and a PSU's OCP/OPP can trip on those at any nominal rating. Also relevant: unit age/degradation, and whether the GPU is fed from split rails. And at the other end, some PSUs regulate poorly at the very low draw of a 4090 at idle - which would cover the idle hangs.

3. VANILLA KERNEL TEST. CachyOS kernels carry heavy scheduler/mm patching, and a bug there can hard-lock with zero logs. linux-cachyos-lts 6.18.52 is already installed so booting it is free, but core/linux-lts 6.18.54 is the better test because it removes CachyOS's patches entirely rather than just changing version.

4. BIOS: CURVE OPTIMIZER / PBO / FCLK. A CO undervolt is the classic Zen 3 random-freeze cause and is worst at idle, which fits hangs #1, #2 and #5. The flash reset defaults, so this only matters if something was re-applied afterwards - needs asking. Also worth pinning FCLK explicitly instead of auto with 4 DIMMs.

5. CORSAIR MP600 BOOT DRIVE. Phison E16, firmware EGFM11.3, and it is the root device - a controller lockup takes the system down with nothing logged. The APST workaround addresses power-state latency, not a controller wedge. Worth checking Corsair for a newer firmware; a longer test is booting from one of the SN850X drives instead.

6. VOLTAGE / VRM MONITORING. There is currently no rail visibility at all - only CPU and NVMe temps. nct6683 is available with force=1 (mainline, 'Set to one to enable support for unknown vendors'), and AUR nct6687d is the better-maintained option for MSI. Caveat worth stating: force=1 on an unknown vendor can report bogus values and concurrent EC access is not risk-free. Paired with logging sensors every few seconds, it would make the PSU theory measurable instead of speculative.

7. TAKE THE 4090 OUT OF THE EQUATION. Most decisive single test left: run headless over SSH with the card removed, or at minimum blacklist nvidia and stay on the console. Surviving several days that way would narrow this enormously.

Eliminated so far: nvme APST, pcie_aspm, BIOS 1.40->1.D4, Power Supply Idle Control, the greeter, memory speed, bad DIMM cells, thermal, OOM, GPU driver faults (no Xid), MCE, PCIe AER.

---
▸ 2026-09-30T10:55:00Z [claude]
HANG #6 + the stress-ng result reorder the leaderboard substantially.

HANG #6: Sep 29 08:16:24 -> 08:33:23, only 16m59s, logged in. Sat dead 12h44m01s because the watchdog was never armed (see dots-d532 - sp5100_tco is deny-listed by cachyos-settings). Post-BIOS-1.D4, post-Power-Supply-Idle-Control, post-Secure-Boot-off, on kernel 7.2.8. Last line: 'plocate-updatedb.service: Consumed 19.573s CPU time over 21.285s wall clock time, 1.6G memory peak' - it froze at the exact instant that job FINISHED.

THE LOAD->IDLE PATTERN, now visible across the set:
  #5 froze exactly at 'snapperd.service: Deactivated successfully'    (job ending -> idle)
  #6 froze exactly at 'plocate-updatedb ... Consumed 19.573s CPU'     (job ending -> idle)
  #3 froze shortly after a heavy journalctl burst subsided
  #1, #2 froze during long idle at the greeter
NEVER during sustained load.

WHAT THE 9.5h stress-ng RUN ACTUALLY PROVES: 32 threads pegged for 9h34m with no hang. So sustained all-core load, CPU VRM, and thermals are fine. But cpu0 STILL entered C2 1,723,227 times during it (1787s total, ~1ms average), so brief per-core idle dips are demonstrably harmless. What never happened under load is ALL CORES IDLE SIMULTANEOUSLY - which is the hardware precondition for package C6.

NEW #1 SUSPECT: PACKAGE DEEP IDLE (PC6). It explains all six hangs and the 9.5h survival, and it explains why Power Supply Idle Control did not help - that setting governs VRM current behaviour at idle, it does not stop the package entering PC6.
DECISIVE TEST, free and no reboot needed (state2/disable is root-writable):
  echo 1 | sudo tee /sys/devices/system/cpu/cpu*/cpuidle/state2/disable
then leave the machine idle overnight. Surviving a long idle with C2 disabled implicates PC6; hanging anyway exonerates it. Costs idle power and temps, fully reversible with echo 0. Note only 3 states exist (POLL/C1/C2) under acpi_idle, and there is no package-level sysfs knob - blocking core CC6 is what prevents PC6. turbostat is not installed; installing it would let 'Pkg%pc6' be measured directly.

IMPORTANT: the stress test does NOT discriminate between PC6 instability and PSU low-load regulation - both predict exactly 'fails at idle, survives load'. So the PSU check is still live, but it should be about behaviour at very low draw, not wattage headroom or 4090 transients.

MEMORY IS NOT CLEARED BY THIS RUN: '--vm 32' without --vm-bytes uses the 256 MB default, which the man page states is the TOTAL shared across workers (8 GB even on the per-worker reading) - a rounding error against 125 GB. The run was effectively a CPU/cache soak. A real contention test is still outstanding: stress-ng --vm 32 --vm-bytes 90% --verify.

12VHPWR weakened but unchecked - the GPU idled all night with the display on and nothing happened, but it was never stressed. Vanilla-kernel test now more specifically about the acpi_idle path.

![cstate-cost](artifacts/dots-df8e/cstate-cost)

---
▸ 2026-10-01T01:29:00Z [claude]
A/B measures idle package power and Tctl with cpuidle C2 disabled vs enabled, then restores C2 to disabled from an EXIT trap so Ctrl-C or an error cannot leave the machine exposed. Reads RAPL via /sys/class/powercap/intel-rapl:0 (AMD implements the RAPL MSRs, and intel_rapl_msr is loaded here), handles the counter wrap at max_energy_range_uj = 65532610987 uJ, and toggles all 32 CPUs. energy_uj is root-only, which is why this needs sudo rather than being something I could measure directly.

---
▸ 2026-10-01T01:29:00Z [claude]
24-HOUR IDLE RUN WITH C2 DISABLED: NO HANG. Strongest evidence yet for the package-deep-idle theory.

Quality of the evidence, stated carefully:
  * uptime 24h09m, and genuinely idle - load average 0.08/0.06/0.06, and cpu0 spent 50407s of 86955s in C1 = 58% residency. So it has been idling heavily, just into C1 instead of C2.
  * C2 counters frozen at their pre-disable values (usage 2282997, time 3341s), confirming it stayed off the whole run.
  * Longest prior time-to-hang was 13h06m; this run is 1.84x that.
  * Rough arithmetic: 6 hangs across roughly 45h of pre-fix uptime gives an MTTF near 7h, so surviving 24h is about exp(-24/7) ~ 3% likely had nothing changed. Suggestive at ~97%, not proof.

COST, as far as it can be measured without root: Tctl 47.4 / Tccd1 42.0 / Tccd2 36.8 now (C2 off, idle) against Tctl 44.1 / Tccd1 37.2 / Tccd2 29.5 recorded Sep 27 (C2 on, idle) - roughly +3 to +7 C. Not a controlled comparison (different day and ambient), which is why the attached cstate-cost script does the A/B back to back. Idle package power is the real cost and needs the script; CC6/PC6 is where most Zen idle saving lives, so expect tens of watts. Genuine upside to name: removing an 18us exit latency improves interactive/audio/network latency determinism.

NEXT, in order:
  1. PERSIST IT FIRST. The sysfs write dies at reboot, so a reboot right now silently re-exposes the machine. Add processor.max_cstate=1 to KERNEL_CMDLINE[default] in /etc/default/limine, then limine-update. That applies from boot with no window, survives updates, and is greppable - preferable to the BIOS 'Global C-state Control = Disabled' route, which is more robust but platform-wide and invisible from the OS.
  2. FIX THE WATCHDOG (dots-d532). Still deny-listed, still no /dev/watchdog. It is the safety net for this diagnosis being wrong or partial.
  3. OPTIONALLY CONFIRM WITH ONE A/B: re-enable C2 and see whether it hangs inside ~13h. That is the difference between 97% and known, at the cost of one hang. Worth doing once rather than carrying a permanent power penalty on a maybe.
  4. CLEAN UP THE CARGO CULT: pcie_aspm=off and nvme_core.default_ps_max_latency_us=0 are both still on the cmdline, both aimed at the same 'something breaks at idle' family, and both already falsified (hangs occurred with each active). Remove one at a time now that a known-good lever exists - it also claws back some of the idle power.
  5. LONG TERM this is a workaround, not a fix. Likely SoC/AGESA behaviour around package C6 on this CPU+board+memory combination. Already on the newest BIOS (1.D4), so nothing further to apply; revisit after a future AGESA, and check AMD CBS for a narrower knob.

---
▸ 2026-10-01T02:27:48Z [Joel Webber]
SHORN. The diagnosis is complete and the workaround is deployed and verified. Follow-up is dots-e579; the narrative is written up in docs/idle-hardlock-notes.md; the hang-by-hang forensics stay in this file.

VERDICT: package deep idle (PC6) on this 5950X + MSI MS-7D53 platform. Worked around with processor.max_cstate=1 on the kernel cmdline, which prevents acpi_idle registering C2 at all, so no core ever enters CC6 and the package can never reach PC6.

CONFIRMED THIS BOOT (0, 2026-09-30 22:12): cmdline carries processor.max_cstate=1; /sys/devices/system/cpu/cpu0/cpuidle/ contains only state0 (POLL) and state1 (C1), with state2 absent entirely rather than disabled. Preceding boot -1 ran 24h53m09s, classified CLEAN by hang-watch - the longest run in the whole recorded history and 1.9x the longest pre-fix time-to-hang.

THE SIX HANGS, final table. Every one abrupt mid-line, no shutdown sequence, no panic, no pstore record, no Xid/NVRM/MCE/thermal/AER, and the NMI hard-lockup detector never fired even when armed:
  #1  2026-09-23 02:25:21  after 10h41m41s  sat dead 19h01m
  #2  2026-09-24 21:33:01  after 13h05m28s  sat dead 38h11m  at greeter
  #3  2026-09-26 18:03:23  after  6h19m30s  sat dead 19h02m  at greeter
  #4  2026-09-27 16:25:39  after  0h15m22s  sat dead  0h06m  logged in, heavy load
  #5  2026-09-27 21:41:37  after  2h11m11s  sat dead 10h31m  logged in, idle
  #6  2026-09-29 08:33:23  after  0h16m59s  sat dead 12h44m  logged in
Roughly four days of cumulative dead time.

WHAT CRACKED IT, in order:
  1. Journal retention. The real starting point - SystemMaxUse was effectively 50M (and joels own 26 was 26 BYTES, and vendor-overridden). Raising it to 4G took retention from 1 boot to 9+ and immediately surfaced two captured hangs. Nothing else was possible before this.
  2. A 9h34m stress-ng run at 32 threads SURVIVED. That eliminated sustained load, CPU VRM and thermals in one shot.
  3. The crucial detail in that run: cpu0 still entered C2 1,723,227 times (~1 ms average). So brief PER-CORE idle is demonstrably harmless. What never happens under load is ALL CORES IDLE SIMULTANEOUSLY - which is precisely the hardware precondition for package C6.
  4. Hangs #5 and #6 froze at the exact instant a job finished (snapperd deactivating; plocate-updatedb reporting its CPU time). A load->idle transition, which is when the package first becomes eligible for PC6.
  5. 24h idle with C2 disabled, then this 24h53m boot with it gone from the cmdline. Both clean.
Confidence ~97% (exp(-24/7) against a ~7h MTTF), not proof. The one A/B that would settle it is carried in dots-e579.

ELIMINATED ALONG THE WAY, each by evidence rather than assumption: nvme_core.default_ps_max_latency_us=0 and pcie_aspm=off (hangs with each active); BIOS 1.40->1.D4 plus the microcode bump (hang #4 after); Power Supply Idle Control = Typical Current Idle (hang #4 after - and the PC6 finding explains why it could not help: it governs VRM current at idle, it does not stop the package entering PC6); the noctalia greeter; memory speed; bad DIMM cells (memtest86+ x2); thermal; OOM; GPU driver faults; MCE; PCIe AER; and the clocksource watchdog timeout, which was a red herring appearing once per boot in clean boots too.

TWO CORRECTIONS I OWE THIS RECORD:
  * I called the greeter the leading suspect on a 2-for-2 correlation, then had to retract it when #4 hit under load and #5 hit logged-in-idle. n=2 on a confounded variable ("never logged in" vs "nobody touched it") was too thin to lead with.
  * I sheared dots-d532 early, then had to regrow it when the first real hang showed pstore was unreadable and systemd-pstore.service disabled - and the watchdog then turned out never to have worked at all until Sep 30, which is why hang #6 sat dead 12h44m. "Configured" was not "working" three separate times on that yak (RuntimeWatchdogUSec=0 needing daemon-reexec; the cachyos-settings deny-list; the initramfs).

STILL A WORKAROUND. Most likely SoC/AGESA behaviour around package C6 on this CPU + board + memory combination; already on the newest BIOS, so nothing further to apply. Costs ~12 W and ~2 C at idle, measured back-to-back. Revisit after a future AGESA - dots-e579.
