# Idle Hard-Lock Notes (j15r)

Investigation into the intermittent hard hangs on `j15r` after long idle periods.
Tracked as `dots-df8e` and children. Last updated 2026-09-27.

Machine: MSI MS-7D53 (MPG X570S EDGE MAX WIFI), Ryzen 9 5950X, RTX 4090 (nvidia
615.71.09 open kernel module), 3× NVMe, CachyOS, Limine bootloader, niri + noctalia
under greetd.

## Status

| | |
|---|---|
| **Leading hypothesis** | The hangs happen at the **noctalia greeter**, not in a niri session. 2-for-2 on captured hangs. |
| **Fixed** | Journal retention (4G, ~6 boots). Lockup detectors + panic-on-lockup live. |
| **Open** | `efi_pstore.pstore_disable=0` not yet on the cmdline — a panic still leaves no record. Greeter log flood. BIOS 1.40 from 2022. |
| **Ruled out so far** | GPU faults (no Xid/NVRM), MCE, thermal, PCIe AER — all silent before both hangs. |

Current kernel cmdline:

```
splash rw rootflags=subvol=/@ root=UUID=8967db38-... nvme_core.default_ps_max_latency_us=0 pcie_aspm=off
```

## 1. Two captured hangs, and what they have in common

This is the payoff from fixing journal retention (§2) — the very next look at the
journal had two hangs in it.

| Boot | Ran | How it ended |
|---|---|---|
| −4 | Sep 23 22:29:22 → Sep 24 02:40:26 | **clean** — real shutdown markers |
| −3 | Sep 24 08:27:33 → **21:33:01** (13h06m) | **hang** — stops mid-line, no shutdown sequence |
| −2 | Sep 26 11:43:53 → **18:03:23** (6h20m) | **hang** — stops mid-line, no shutdown sequence |

Both hung boots simply stop, mid-way through a greeter log line, with no
`systemd-shutdown`, no unmount, no journal-stopped record.

### The correlation

The two boots that hung are **exactly the two boots where nobody ever logged in**:

- `greeter exited with status` never appears in either.
- The boot-time compositor (PID 1048 and 1042 respectively) is still the last thing
  logging at the moment of death.
- Both boots that *did* start a niri session (−4 and the current one) ended cleanly or
  are still up.

In both cases the last non-greeter activity was routine hourly `snapper-cleanup`,
followed by nothing but the 60 Hz greeter flood — 52 minutes of it on boot −3, about 7
minutes on boot −2 — and then the cut. Time-to-death varies (13h06m vs 6h20m), so it is
not a fixed timer.

**Caveat, stated plainly:** n=2, and "never logged in" is confounded with "nobody
touched the machine." A logged-in-but-idle-for-13h boot that survives would separate
those two explanations. No such sample exists yet — boot −4 was logged in but only for
4h before a deliberate shutdown. So this is a strong hint, not proof.

It does, however, point at the greeter/compositor path rather than the NVMe/PCIe theory
that motivated the original cmdline flags.

**Cheapest decisive experiment:** leave the machine logged into niri overnight instead
of sitting at the greeter. If it survives repeatedly, the greeter is implicated.

### What was *not* happening

Across both hangs, zero of: `Xid`, `NVRM` errors, GPU hang/reset, `MCE`, machine check,
thermal or throttling events, PCIe AER (all `aer_dev_*` counters read zero). The machine
reported nothing at all before wedging — which is what a true hard lock looks like, and
why §3 matters.

Incidental oddity from boot −4, possibly related to `dots-1155`:

```
niri: WARN vblank_throttle: output DP-1 running faster than expected,
      expected refresh 13.337065ms, got vblank after 6.658ms
```

13.337 ms is 75 Hz, 6.658 ms is 150 Hz — niri believes it configured 75 and the display
is delivering double. Not a hang cause, but a second sign of display-pipeline weirdness
on this setup.

## 2. Journal retention — fixed

**Resolved**, and worth keeping the lesson. The original hand-edit to
`/etc/systemd/journald.conf` was inert for two independent reasons:

1. **Missing unit.** `SystemMaxUse=26` parses as *26 bytes* — unsuffixed systemd size
   values are bytes.
2. **Overridden anyway.** `/usr/lib/systemd/journald.conf.d/00-journal-size.conf` ships
   `SystemMaxUse=50M`, and for `foo.conf` + `foo.conf.d/` **the main file is read first,
   so drop-ins win** — including a vendor drop-in over an admin main file.

The fix was a drop-in in `/etc` sorting after `00-`:

```ini
# /etc/systemd/journald.conf.d/10-local.conf
[Journal]
SystemMaxUse=4G
```

Now effective: `cat-config` shows `50M` at line 55 overridden by `4G` at line 59, disk
usage is ~1.8 G, and six boots are retained back to Sep 23 — which is what made §1
possible.

## 3. Lockup detection and post-mortem capture

### Done

`nowatchdog` and `quiet` are off the cmdline, and `/etc/sysctl.d/90-lockup-diag.conf` is
installed (kept in-repo at `.yaks/artifacts/dots-d532/90-lockup-diag.conf`):

```
kernel.nmi_watchdog = 1      kernel.hardlockup_panic = 1
kernel.watchdog = 1          kernel.softlockup_panic = 1
kernel.soft_watchdog = 1     kernel.panic_on_oops = 1
kernel.panic = 20            kernel.printk = 7 4 1 7
```

The hard-lockup detector genuinely initialised — this was the real risk, since the
perf-based detector can fail to claim a counter:

```
kernel: NMI watchdog: Enabled. Permanently consumes one hw-PMU counter.
```

### Two CachyOS kill switches that made this non-obvious

Removing `nowatchdog` from the cmdline was **not sufficient**.
`/usr/lib/sysctl.d/70-cachyos-settings.conf` re-pins two settings on every boot:

- line 30: `kernel.nmi_watchdog = 0` (comment cites boot speed, performance, power)
- line 36: `kernel.printk = 3 3 3 3` ("To hide any kernel messages from the console")

Observed directly: after the cmdline edit, `kernel.watchdog` flipped 0 → 1 but
`kernel.nmi_watchdog` stayed 0 and `printk` stayed `3 3 3 3` until the `/etc` override
was installed.

### `sysctl.d` precedence (different from journald's!)

Per `sysctl.d(5)`:

> All configuration files are sorted by their filename in lexicographic order, regardless
> of which of the directories they reside in. If multiple files specify the same option,
> the entry in the file with the lexicographically latest name will take precedence.

So the **filename** decides, across all four of `/etc`, `/run`, `/usr/local/lib`,
`/usr/lib`. Directory priority applies only to files with the *same basename*, and then
it is total replacement. Recommended bands: 10–40 for `/usr/`, **60–90 for `/etc/`** —
hence `90-lockup-diag.conf`. There is no `/etc/sysctl.conf` on this box.

(To mask a vendor file wholesale instead: `ln -s /dev/null /etc/sysctl.d/<same-name>`.)

### Remaining: nothing persists a panic

`hardlockup_panic=1` means the next hang should panic rather than wedge silently, and
`panic=20` brings the box back — but **the panic text will not survive the reboot.**
Console visibility is irrelevant here: plymouth is installed (so `splash` is live) and
by hang time the greeter owns the display, so nobody is watching a VT.

`efi_pstore` is the pragmatic capture path. This kernel has `CONFIG_EFI_VARS_PSTORE=y`
but `CONFIG_EFI_VARS_PSTORE_DEFAULT_DISABLE=y`, so it needs an explicit flag. Add
`efi_pstore.pstore_disable=0` to `KERNEL_CMDLINE[default]`, then `limine-update`.
Ready-to-run script: `.yaks/artifacts/dots-d532/add-pstore-cmdline.sh`.

After rebooting, verify:

```sh
cat /proc/cmdline
journalctl -k | grep -i pstore    # want "Registered efi as persistent store backend"
ls /sys/fs/pstore/                # where a captured panic lands
```

It writes to EFI NVRAM, so clear old records once read. Alternatives considered:
`ramoops` (`CONFIG_PSTORE_RAM=m`) avoids NVRAM but needs a reserved physical memory
region, which is fiddly to pick safely on x86; `netconsole` (`CONFIG_NETCONSOLE=m`)
needs a second machine listening but is the only option if the lock is hard enough that
even the NMI detector never fires. There are no ACPI ERST/BERT tables, so firmware-side
logging is unavailable.

## 4. The greeter log flood (`dots-3d5e`) — still open

`noctalia-greeter-compositor` emits one wlroots line at **exactly 60/second**, one per
frame, for as long as the greeter is up:

```
[types/output/output.c:1013] Direct scan-out disabled by software cursor
```

Roughly 1.47 M lines per idle session. Still ~41 k lines in the current boot; no
`greetd.service` rate-limit drop-in installed yet. Less catastrophic at 4 G retention,
but per §1 this is no longer merely a log-volume problem — it is the prime suspect's
environment.

### The documented knob does not work

`/usr/bin/noctalia-greeter-session:63` looks like the answer and isn't:

```sh
# Raise log level with WLR_LOG=info when debugging (also set NOCTALIA_GREETER_LOG=stderr).
export WLR_LOG="${WLR_LOG:-error}"
```

- `strings /usr/bin/noctalia-greeter-compositor | grep -c WLR_LOG` → **0**. Never read.
  (wlroots doesn't read an env var for verbosity either; the compositor must pass one.)
- There is exactly **one** `wlr_log_init` call site and its verbosity is a hardcoded
  immediate: `mov $0x2,%edi` → `WLR_INFO`.

So there is no supported way to quiet it. Worth reporting upstream against
noctalia-greeter 1.5.0.

Env vars the binary *does* read: `DISPLAY`, `GREETD_SOCK`, `GREETER_BIN`,
`NOCTALIA_GREETER_IDLE_TIMEOUT`, `NOCTALIA_GREETER_LOG`, `NOCTALIA_GREETER_STATE_DIR`.

### Workarounds

Rate-limit the unit rather than the app — the flood arrives via syslog under greetd:

```ini
# systemctl edit greetd.service
[Service]
LogRateLimitIntervalSec=30s
LogRateLimitBurst=200
```

`NOCTALIA_GREETER_IDLE_TIMEOUT` is the more interesting lever now: if it parks the
compositor after idle, it changes exactly the condition under which the machine dies.

## 5. BIOS (`dots-c1e2`) — still open

Running **1.40, dated 2022-09-01** — about four years of AGESA fixes unapplied, several
targeting Ryzen idle stability. The classic companion is **Power Supply Idle Control →
Typical Current Idle**, a long-standing fix for Zen hard-locks at low load; BIOS-only,
invisible from the OS.

**No capsule/fwupd path exists**: `/sys/firmware/efi/esrt` is absent and `fwupd` isn't
installed, so LVFS is not an option on this board. Use **M-FLASH**: latest BIOS for
*MPG X570S EDGE MAX WIFI (MS-7D53)* → unzip to FAT32 USB → <kbd>Del</kbd> → Utilities →
M-FLASH. Check the rear I/O for a Flash BIOS Button too (file renamed `MSI.ROM`, no CPU
needed). MSI Center is Windows-only.

### Boot survives the flash

A flash typically clears NVRAM boot entries. Currently:

```
Boot0004* Limine   ...\EFI\LIMINE\LIMINE_X64.EFI
Boot0005* UEFI OS  ...\EFI\BOOT\BOOTX64.EFI
```

`Boot0005` is the Limine fallback at the removable-media path, which firmware boots by
default even with empty NVRAM — so the machine stays bootable. Re-register the named
entry afterward with `sudo limine-install`.

## 6. On `pcie_aspm=off`

Now applied (added to the cmdline 2026-09-27), but still **unsupported by evidence**:

- `/sys/module/pcie_aspm/parameters/policy` read `[default]` (firmware-controlled)
  beforehand, so the flag does change behaviour — it is not a no-op.
- But every `aer_dev_correctable` / `aer_dev_fatal` / `aer_dev_nonfatal` counter across
  all PCIe devices is zero, and no NVMe timeouts appear in any retained boot.
- `nvme_core.default_ps_max_latency_us=0` did take effect (confirmed in
  `/sys/module/nvme_core/parameters/`).

Given §1 points at the greeter, this is a confound with a small idle-power cost and no
supporting signal. Reasonable to drop once the greeter hypothesis is tested — but it
costs nothing to leave in place meanwhile, and removing it mid-experiment would change
two variables at once.
