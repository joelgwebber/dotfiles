---
id: dots-dfbf
title: 4x32GB at XMP may be the real hard-lock cause
type: task
priority: 1
created: '2026-09-27T22:30:31Z'
updated: '2026-09-28T00:01:51Z'
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

---
▸ 2026-09-28T00:01:51Z [claude]
Joel reports A-XMP was ALREADY enabled, set to 'XMP Profile 1', and that profile appeared to be at 2133 / 1.2 V.

That reading is itself the finding: 2133 MT/s at 1.2 V is the DDR4 SPD-safe fallback, not a plausible XMP profile. XMP profiles by definition exceed JEDEC base, and DDR4 kits above ~2666 essentially always specify around 1.35 V. 'XMP Profile 1 selected' + 'running 2133 / 1.2 V' is the signature of the board selecting the profile and then FAILING TO TRAIN it, falling back to safe values. That is the classic 4x32GB AM4 outcome - four likely-dual-rank DIMMs push the Zen 3 IMC past what it can train.

CORRECTION to my previous note: if the board was already falling back to 2133 before the flash - likely, since XMP was already enabled - then memory speed is NOT a newly changed variable and the confound I warned about does not exist. The observation window really is 'new BIOS + Power Supply Idle Control'. I never measured pre-flash memory speed, so this is inference, not proof.

The hypothesis gets STRONGER though: a config that cannot train its own rated profile is running at the edge of the memory controller's capability, and falling back to 2133 does not establish stability - fallback timings on 4x32GB at 1.2 V can still be marginal.

NEEDED to settle it (root): sudo dmidecode -t 17 | grep -E 'Size|Speed|Part Number|Manufacturer|Rank|Configured' - the part number gives the rated spec, which tells us whether 2133 is a fallback or actually the kit's rating.

FASTER PATH THAN WAITING: no memory stress tool is installed; memtester and stress-ng are both in the repos (cachyos-extra-v3 / extra). Given hang #3 happened under load, a stress run is a plausible reproducer, and a reproducible hang is worth far more than days of waiting. Risk to state plainly: it may hard-lock the box - which is the point.
