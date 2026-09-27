---
id: dots-dfbf
title: 4x32GB at XMP may be the real hard-lock cause
type: task
priority: 1
created: '2026-09-27T22:30:31Z'
updated: '2026-09-27T22:30:51Z'
parent: dots-df8e
labels:
- linux
---

---
▸ 2026-09-27T22:30:51Z [claude]
dmidecode -t 17 after the flash shows all four DIMMs at Speed 2133 MT/s, Configured Memory Speed 2133 MT/s, Configured Voltage 1.2 V - i.e. JEDEC DDR4 baseline with A-XMP off, because the flash restored BIOS defaults. Total is 125 GiB, so this is 4x32GB.

WHY THIS IS A LEAD, NOT JUST A PERF REGRESSION: 4x32GB (very likely dual-rank) on AM4 is a well-known strain on the Zen 3 memory controller, and many such kits are not actually stable at their rated XMP even when they POST and pass light use. Memory instability on non-ECC RAM produces exactly the signature seen here: instant hard freeze, no logs, no MCE, no Xid, nothing for the NMI watchdog to catch. It fits all three hangs better than the greeter did, and it fits hang #3's under-load profile especially well.

CONFOUND TO AVOID: the machine is currently at the most conservative memory config it will ever run (2133 / 1.2 V). So the observation period about to start is not 'new BIOS' - it is 'new BIOS AND memory underclocked'. Two variables at once.

RECOMMENDED: re-enable A-XMP to joel's normal profile in the same BIOS trip as Power Supply Idle Control. That restores performance and makes the BIOS the single changed variable versus the hang history. If a hang recurs on the new BIOS at XMP, deliberately dropping memory speed (or just FCLK/timings) becomes the next test, and a clean one.

Cheap independent check that does not need a reboot: a long memtester / stressapptest run at whatever speed is configured.
