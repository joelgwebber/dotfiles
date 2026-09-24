# Idle Hard-Lock Notes (j15r)

Investigation notes for the intermittent hard hangs on `j15r` after long idle periods.
Tracked as `dots-df8e` and children.

Machine: MSI MS-7D53 (MPG X570S EDGE MAX WIFI), Ryzen 9 5950X, RTX 4090 (nvidia
615.71.09 open kernel module), 3× NVMe, CachyOS, Limine bootloader, niri + noctalia
under greetd.

## Summary

There is still **no direct evidence** of what causes the hangs, because the journal
cannot retain it. Fixing observability comes before adding more kernel cmdline flags.

Current cmdline:

```
quiet nowatchdog splash rw rootflags=subvol=/@ root=UUID=8967db38-... nvme_core.default_ps_max_latency_us=0
```

## 1. Journal retention (`dots-fe9a`)

The `SystemMaxUse` edit in `/etc/systemd/journald.conf` is **ineffective**, for two
independent reasons:

1. **Missing unit.** `SystemMaxUse=26` is parsed as *26 bytes* — systemd size values
   default to bytes when unsuffixed. It needs `2G` / `26G` / etc.
2. **Overridden anyway.** `/usr/lib/systemd/journald.conf.d/00-journal-size.conf` ships
   `SystemMaxUse=50M`, and **drop-ins are read after the main file, so they win**.
   `systemd-analyze cat-config systemd/journald.conf` shows `=26` at line 28 and
   `=50M` at line 55.

Empirically confirmed: `journalctl --disk-usage` reports ~48M, i.e. still the 50M cap.

The fix is a drop-in in `/etc` whose name sorts *after* `00-journal-size.conf`:

```sh
sudo install -d /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/10-local.conf >/dev/null <<'EOF'
[Journal]
SystemMaxUse=4G
EOF
sudo systemctl restart systemd-journald
journalctl --disk-usage   # confirm the cap moved
```

Revert the hand-edit to `/etc/systemd/journald.conf` so there's one source of truth.

## 2. The greeter log flood (`dots-3d5e`)

`noctalia-greeter-compositor` emits this single wlroots line at **exactly 60/second**
(one per frame), for as long as the greeter is up:

```
[types/output/output.c:1013] Direct scan-out disabled by software cursor
```

Measured: 92,012 of 92,034 messages in the retained window. `greetd` came up at
09:13:00 and the compositor exited at 16:02:15 — 6h49m, so roughly **1.47M lines** for
one idle session. At 50M retention that's ~26 minutes of history, which is why
`journalctl --list-boots` shows only one boot and why the current boot's journal starts
6h23m *after* `/proc/stat` btime.

### The documented knob does not work

`/usr/bin/noctalia-greeter-session` exports it and says to raise it for debugging:

```sh
# Raise log level with WLR_LOG=info when debugging (also set NOCTALIA_GREETER_LOG=stderr).
export WLR_LOG="${WLR_LOG:-error}"
```

But `WLR_LOG` is dead:

- `strings /usr/bin/noctalia-greeter-compositor | grep -c WLR_LOG` → **0**. The
  compositor never reads it. (wlroots itself doesn't read an env var for log level
  either; the compositor must pass a verbosity to `wlr_log_init`.)
- There is exactly **one** `wlr_log_init` call site, and its verbosity argument is
  hardcoded: `mov $0x2,%edi` → `WLR_INFO`.

So `WLR_LOG=error` in the session script has no effect, and there is no supported way
to quiet the compositor. This is an upstream noctalia-greeter bug worth reporting.

Env vars the binary *does* read: `DISPLAY`, `GREETD_SOCK`, `GREETER_BIN`,
`NOCTALIA_GREETER_IDLE_TIMEOUT`, `NOCTALIA_GREETER_LOG`, `NOCTALIA_GREETER_STATE_DIR`.

### Workaround: rate-limit the unit, not the app

Because the flood arrives via syslog under greetd, `journald`'s per-unit rate limiter is
the clean lever:

```sh
sudo systemctl edit greetd.service
```

```ini
[Service]
LogRateLimitIntervalSec=30s
LogRateLimitBurst=200
```

`NOCTALIA_GREETER_IDLE_TIMEOUT` is also worth exploring — if it parks the compositor
after idle it would cut the flood at the source *and* change what the machine is doing
during the idle windows when it hangs.

## 3. Post-mortem capture (`dots-d532`)

Nothing is currently able to record a hard lock. Every detector is off:

| Setting | Value | Note |
|---|---|---|
| `kernel.nmi_watchdog` | `0` | disabled by `nowatchdog` |
| `kernel.watchdog` | `0` | disabled by `nowatchdog` |
| `kernel.hardlockup_panic` | `0` | a detected lockup only warns |
| `kernel.panic` | `0` | never auto-reboots |
| `kernel.panic_on_oops` | `0` | |
| `/dev/watchdog*` | absent | no hw watchdog bound |

But the kernel *has* the machinery — from `/proc/config.gz`:

```
CONFIG_HARDLOCKUP_DETECTOR=y
CONFIG_HARDLOCKUP_DETECTOR_PERF=y
CONFIG_SOFTLOCKUP_DETECTOR=y
CONFIG_EFI_VARS_PSTORE=y
CONFIG_EFI_VARS_PSTORE_DEFAULT_DISABLE=y   # needs efi_pstore.pstore_disable=0
CONFIG_PSTORE_RAM=m                        # ramoops
CONFIG_NETCONSOLE=m
```

**`nowatchdog` is the single most counterproductive flag on the cmdline for this
problem.** It disables the NMI hard-lockup detector, which is precisely the mechanism
that would notice a wedged CPU, panic, and leave a record.

Plan, in order:

1. Drop `nowatchdog` from `KERNEL_CMDLINE[default]` in `/etc/default/limine`, then
   `sudo limine-update`.
2. Make a detected lockup panic and reboot, so it's recorded and the box comes back:
   ```ini
   # /etc/sysctl.d/99-lockup.conf
   kernel.hardlockup_panic = 1
   kernel.panic_on_oops = 1
   kernel.panic = 20
   ```
3. Give the panic somewhere to land across the reboot. Easiest is EFI-variable pstore —
   add `efi_pstore.pstore_disable=0` to the cmdline; dumps then appear in
   `/sys/fs/pstore`. It writes to EFI NVRAM, so keep an eye on it and clear old records;
   `ramoops` avoids NVRAM but needs a reserved memory region, which is fiddlier on x86.
4. If the lock is hard enough that even the NMI detector never fires, `netconsole` to
   another machine is the only remaining option — it streams kmsg over UDP as it
   happens rather than relying on anything surviving locally.

Note that `quiet` also suppresses console output; worth dropping alongside `nowatchdog`
while diagnosing.

## 4. BIOS update (`dots-c1e2`)

Running **1.40, dated 2022-09-01** — roughly four years of AGESA fixes unapplied,
several of which target Ryzen idle stability. The classic companion setting is
**Power Supply Idle Control → Typical Current Idle**, a long-standing fix for Zen
hard-locks at low load; it is BIOS-only and not visible from the OS.

**There is no capsule/fwupd path.** `/sys/firmware/efi/esrt` does not exist and `fwupd`
isn't installed, so LVFS is not an option on this board. Use **M-FLASH**:

1. Download the latest BIOS for *MPG X570S EDGE MAX WIFI (MS-7D53)* from MSI support.
2. Unzip onto a FAT32 USB stick.
3. Reboot, <kbd>Del</kbd> into BIOS → Utilities → M-FLASH, pick the file.

The board may also have a rear-I/O **Flash BIOS Button** (flashes from USB with no CPU
or boot required, file renamed to `MSI.ROM`) — check the rear panel or manual.
MSI Center is Windows-only and irrelevant here.

### Boot survives the flash

A BIOS flash typically clears NVRAM boot entries. Currently:

```
Boot0004* Limine   ...\EFI\LIMINE\LIMINE_X64.EFI
Boot0005* UEFI OS  ...\EFI\BOOT\BOOTX64.EFI
```

`Boot0005` is the Limine fallback at the removable-media path, which firmware boots by
default even with an empty NVRAM — so the machine stays bootable. If NVRAM is wiped,
re-register the named entry with `sudo limine-install`.

## 5. On `pcie_aspm=off`

Not yet justified, though not a no-op either:

- `/sys/module/pcie_aspm/parameters/policy` reads `[default]` (firmware-controlled), so
  the flag *would* change behaviour.
- But every `aer_dev_correctable` / `aer_dev_fatal` / `aer_dev_nonfatal` counter across
  all PCIe devices is **zero**, and the only kernel message above `warning` this boot is
  a benign `block nvme1n1: No UUID available providing old NGUID`.
- `nvme_core.default_ps_max_latency_us=0` did take effect (confirmed in
  `/sys/module/nvme_core/parameters/`).

Hold it until there's a capture worth correlating against. Adding flags while nothing
can be measured just makes the next hang equally uninformative.

## 6. Reframing "idle"

The machine does not quiesce during these windows. It sits at the greeter with a
wlroots compositor recompositing at 60fps on a 4090 for hours, and it **never sleeps** —
`logind.conf` and `sleep.conf` are both default/empty and there were zero
suspend/hibernate events across the 7h boot examined. Whatever the hang is, it happens
with a compositor actively spinning, not with a parked box. That makes the
GPU/compositor path at least as interesting as the NVMe/PCIe theory that motivated the
original flags.
