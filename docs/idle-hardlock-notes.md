# Idle Hard-Lock Notes (j15r) — resolved

Investigation into the intermittent hard hangs on `j15r`. **Resolved 2026-09-30** with a
workaround, not a true fix. Tracked as `dots-df8e` (shorn); follow-up is `dots-e579`.

Machine: MSI MS-7D53 (MPG X570S EDGE MAX WIFI), BIOS 1.D4 (AGESA 1.2.0.12), Ryzen 9
5950X, 4×32GB DDR4, RTX 4090 (nvidia 615.71.09 open kernel module), 3× NVMe, CachyOS,
Limine bootloader, niri + noctalia under greetd.

## Verdict

**Package deep idle (PC6).** The platform freezes when *all* cores happen to be idle at
once, which is the hardware precondition for the package entering C6. Worked around by
keeping the cores out of CC6 entirely:

```
processor.max_cstate=1
```

in `KERNEL_CMDLINE[default]` in `/etc/default/limine`, then `sudo limine-update`.

This is stronger than the `/sys/.../state2/disable` toggle it replaced: `max_cstate=1`
stops `acpi_idle` **registering** C2 at all, so there is no state to re-enable and no
window at boot before a script runs. Confirmation that it took:

```console
$ ls /sys/devices/system/cpu/cpu0/cpuidle/
state0  state1          # POLL and C1 only — state2 is gone, not merely disabled
```

| | |
|---|---|
| **Cause** | Package C6 entry, almost certainly SoC/AGESA behaviour on this CPU + board + memory combination |
| **Workaround** | `processor.max_cstate=1` — deployed, verified |
| **Cost** | ~12 W and ~2 °C at idle, continuously (measured back-to-back) |
| **Confidence** | ~97%, not proof — see [Honest limits](#honest-limits) |
| **Still open** | Retest after a future AGESA; look for a narrower PC6-only knob in AMD CBS (`dots-e579`) |

Not a fix. The machine is burning 12 W to avoid a platform bug, and the right long-term
move is to retest on newer firmware rather than carry this forever.

## The six hangs

Every one of them: stops **abruptly mid-line**, no shutdown sequence, no panic, no pstore
record, and nothing at all in the final minutes of the journal.

| # | Froze | Ran | State |
|---|---|---|---|
| 1 | 2026-09-23 02:25:21 | 10h41m41s | — |
| 2 | 2026-09-24 21:33:01 | 13h05m28s | at greeter, never logged in |
| 3 | 2026-09-26 18:03:23 | 6h19m30s | at greeter, never logged in |
| 4 | 2026-09-27 16:25:39 | 15m22s | logged in, heavy load |
| 5 | 2026-09-27 21:41:37 | 2h11m11s | logged in, idle |
| 6 | 2026-09-29 08:33:23 | 16m59s | logged in |

Roughly **four days** of cumulative dead time, the worst single instance sitting dead for
38h11m. Times-to-hang span 15 minutes to 13 hours with no pattern, which is why no
timer-based or workload-based theory ever fit.

## How it was cracked

**1. Journal retention first — nothing else was possible before it.** `SystemMaxUse` was
effectively the vendor's 50M. (A hand-written `SystemMaxUse=26` was inert twice over:
unsuffixed systemd sizes are *bytes*, and it sat in `journald.conf` where the vendor
drop-in overrode it anyway.) Raising it to 4G took retention from **1 boot to 9+** and the
very next look at the journal contained two captured hangs.

**2. A 9h34m `stress-ng --vm 32` run survived.** 32 threads pegged, no hang. That
eliminated sustained load, CPU VRM and thermals in a single shot.

**3. The crucial detail inside that run.** `cpu0` still entered C2 **1,723,227 times**
during it — about 1 ms average. So brief *per-core* idle is demonstrably harmless. What
never happens under load is **all cores idle simultaneously**, which is exactly the
precondition for package C6. This is the observation that turned "survives load" from a
dead end into a hypothesis.

**4. Hangs #5 and #6 froze at the precise instant a job finished:**

```
#5  snapperd.service: Deactivated successfully
#6  plocate-updatedb.service: Consumed 19.573s CPU time over 21.285s wall clock
```

A load→idle transition — the moment the package first becomes eligible for PC6.

**5. Two long clean runs.** 24h09m genuinely idle (load 0.08, 58% C1 residency, C2
counters frozen) with C2 disabled by hand, then 24h53m09s with `max_cstate=1` on the
cmdline. The previous longest-ever run before a hang was 13h06m.

This also retroactively explains why **Power Supply Idle Control = Typical Current Idle**
didn't help: it governs VRM current behaviour at idle, it does not stop the package
entering PC6.

## Honest limits

- **~97%, not certain.** Six hangs over ~45h of pre-fix uptime puts MTTF near 7h, so a
  24h survival is about `exp(-24/7)` ≈ 3% likely by chance. Strong, but it is one clean
  run against a bug whose own intervals ranged over three orders of magnitude.
- **Three variables changed in one reboot.** `processor.max_cstate=1` went on while
  `pcie_aspm=off` and `nvme_core.default_ps_max_latency_us=0` both came off. Both removals
  were individually falsified beforehand (hangs occurred with each active), so the risk is
  attributional rather than real — but if a hang recurs, that has to be untangled before
  concluding the C-state theory is wrong.
- **The one test that would settle it** is to take the flag off and leave the machine idle.
  A hang inside ~13h converts 97% into known. It is now survivable, because the watchdog
  finally works.

## Eliminated, each by evidence

`nvme_core.default_ps_max_latency_us=0` and `pcie_aspm=off` (hangs with each active) ·
BIOS 1.40 → 1.D4 and the microcode bump 0x0a20102e → 0x0a201030 (hang #4 after) · Power
Supply Idle Control (hang #4 after) · the noctalia greeter and compositor · memory speed
(hangs happened at the JEDEC 2133/1.2 V fallback) · bad DIMM cells (memtest86+ passed
twice) · thermal (Tctl 44 °C idle, no events ever) · OOM (zero, ever; 125 GiB RAM) · GPU
driver faults (no Xid/NVRM in any hang) · MCE · PCIe AER (all counters zero).

**One red herring worth naming:** `clocksource: Watchdog remote CPU N read timed out`
appears exactly once per substantial boot on a random CPU — including in boots that shut
down cleanly. It never escalated and the clocksource stayed `tsc`. It does not discriminate
hangs.

**Two corrections to the record.** The greeter was called the leading suspect on a 2-for-2
correlation and had to be retracted when #4 hit under load and #5 logged-in-idle; n=2 on a
confounded variable ("never logged in" vs "nobody touched the machine") was too thin to lead
with. And `dots-d532` was sheared early, then regrown, because "configured" turned out not to
mean "working" three separate times — see below.

## Post-mortem capture path (`dots-d532`, shorn)

Four independent layers, all live and verified. Worth keeping even now that the hangs have
stopped, because it is the safety net for this diagnosis being wrong or partial.

| Layer | Mechanism |
|---|---|
| Detect | `nmi_watchdog=1`, `hardlockup_panic=1`, `softlockup_panic=1`, `panic_on_oops=1`, `panic=20` via `/etc/sysctl.d/90-lockup-diag.conf` |
| Record | `efi_pstore.pstore_disable=0` on the cmdline; `systemd-pstore.service` enabled, archiving to `/var/lib/systemd/pstore` |
| Survive | `sp5100_tco` hardware watchdog at 60s, so a platform freeze self-reboots instead of sitting dead overnight |
| Classify | `hang-watch` oneshot unit — validated against the full retained history, flags all 6 hangs with zero false positives across 14 deliberate reboots |

### The watchdog took three attempts

Each failure looked like success from the outside:

1. **`RuntimeWatchdogUSec=0`** despite `/etc/systemd/system.conf.d/watchdog.conf` being
   correct — `system.conf` is only re-read when PID 1 re-executes (`systemctl daemon-reexec`).
2. **`sp5100_tco` deny-listed** by `cachyos-settings` in `/usr/lib/modprobe.d/blacklist.conf`,
   so it never loaded at boot. An earlier hand-`modprobe` had masked this. **This is why hang
   #6 sat dead for 12h44m.** Fixed by shadowing the file at `/etc/modprobe.d/blacklist.conf`
   with only the `iTCO_wdt` line kept.
3. **Loaded too late** — systemd opens the watchdog at PID 1 startup, before
   `systemd-modules-load` runs. Needed `MODULES=(sp5100_tco)` in `/etc/mkinitcpio.conf` plus
   `sudo mkinitcpio -P`.

Verify all three at once:

```console
$ cat /sys/class/watchdog/watchdog0/identity   # SP5100 TCO timer
$ cat /sys/class/watchdog/watchdog0/state      # active
$ systemctl show -p RuntimeWatchdogUSec        # RuntimeWatchdogUSec=1min
```

**New ambiguity this introduces:** `sp5100_tco` does not advertise `WDIOF_CARDRESET`
(options mask `0x8180`), so `bootstatus` is permanently 0 and the kernel cannot report a
watchdog-caused reset — `hang-watch` infers it from the journal instead. A spurious reset
and a real hang therefore read identically (`HANG … sat dead ~Ns`). CachyOS deny-lists this
module deliberately and it has a history of spurious resets on some boards, so a reset whose
dead time is near the 60s timeout, with no other symptom, means **suspect the watchdog
first**.

## Reference: things that made this non-obvious

### Two CachyOS kill switches

`/usr/lib/sysctl.d/70-cachyos-settings.conf` quietly undoes the diagnosis:

- `kernel.nmi_watchdog = 0` — so removing `nowatchdog` from the cmdline is **not enough**;
  this re-disables the detector every boot.
- `kernel.printk = 3 3 3 3` — hides kernel messages from the console, which would hide a
  panic too, on top of `splash`. Want `7 4 1 7` while diagnosing.

Plus `blacklist sp5100_tco` in `/usr/lib/modprobe.d/blacklist.conf` (above).

### `sysctl.d` precedence is *not* like journald's

This bit twice, so it is worth stating both rules side by side:

- **`sysctl.d`** — every file across `/etc`, `/run`, `/usr/local/lib` and `/usr/lib` is
  sorted together **by basename**, and the lexicographically **latest wins**. Directory
  priority only applies to files of the *same name* (full masking). So beating
  `70-cachyos-settings.conf` requires a basename sorting after it — hence
  `90-lockup-diag.conf`. Useful bands: 10–40 for `/usr`, 60–90 for `/etc`.
- **`foo.conf` + `foo.conf.d/` drop-ins** (journald, systemd) — **drop-ins win**, even a
  vendor drop-in over an admin edit to the main file. Hence
  `/etc/systemd/journald.conf.d/10-local.conf` rather than editing `journald.conf`.

And: **unsuffixed systemd size values are bytes.** `SystemMaxUse=26` means 26 bytes.

### Measuring idle power on AMD

AMD implements the RAPL MSRs, so `/sys/class/powercap/intel-rapl:0/energy_uj` works here
(`intel_rapl_msr` is loaded). Root-only, and the counter wraps at `max_energy_range_uj`.
The A/B script is `.yaks/artifacts/dots-df8e/cstate-cost`; it restores the safe state from
an `EXIT` trap so a Ctrl-C cannot leave the machine exposed. Note it toggles `state2`,
which no longer exists under `max_cstate=1`, so re-running it means taking the cmdline flag
off first.

Measured, back to back, same ambient:

| | Package power | Tctl |
|---|---|---|
| C2 disabled | 39.9 W | 35.1 °C |
| C2 enabled | 27.6 W | 32.9 °C |

Most of Zen's idle saving lives in CC6/PC6, so ~12 W is the expected shape. **Upside worth
remembering** before optimising this away: losing the ~18 µs C2 exit latency improves
interactive, audio and network latency determinism.

## Side quests

- **`dots-3d5e`** — the noctalia greeter floods the journal at ~60 msg/s. Exonerated as a
  hang cause; now purely a log-volume bug. The documented `WLR_LOG` knob does not work
  (wlroots reads verbosity at `wlr_log_init` before the greeter sets it), so the practical
  mitigations are a `greetd.service` rate-limit drop-in or an upstream report against
  noctalia-greeter 1.5.0. Still open.
- **`dots-5c4f`** — the BIOS flash silently re-enabled Secure Boot, which is what made
  `memtest.efi` panic: Limine's `LoadImage()` was denied. Note the enforcement asymmetry —
  the firmware happily booted unsigned Limine itself while refusing what Limine then tried
  to load. Since turned off. Still open as a drift note.
- **`dots-c1e2`** — BIOS 1.40 (2022) → 1.D4. Shorn; did not fix the hangs but is the right
  baseline.
- **`dots-dfbf`** — 4×32GB at XMP. Shorn: the hangs happened *at* the JEDEC 2133/1.2 V
  fallback, so the premise could not hold, and memtest86+ passed twice. The machine is
  still running underclocked memory — a performance question now, not a stability one.
- **memtest86+ has no Limine entry** because its package ships a GRUB snippet only.
  `limine-update` has nothing to do; the entry must be hand-written:

  ```
  /Memtest86+
      protocol: efi
      path: boot():/memtest86+/memtest.efi
  ```

  Single leading slash for a top-level entry (double would nest it under Snapshots).
  `boot():/` resolves to the partition holding the config — the ESP, which here *is*
  `/boot`. It survives `limine-update`, which only rewrites its own machine-id-tagged entry.
