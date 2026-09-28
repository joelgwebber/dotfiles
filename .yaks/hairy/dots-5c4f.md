---
id: dots-5c4f
title: Secure Boot silently re-enabled by the BIOS flash
type: bug
priority: 2
created: '2026-09-28T21:18:14Z'
updated: '2026-09-28T21:18:29Z'
parent: dots-df8e
labels:
- linux
---

---
▸ 2026-09-28T21:18:29Z [claude]
Before the BIOS flash, bootctl reported 'Secure Boot: disabled (unknown)' - I checked it on Sep 27 while clearing the TPM-firmware risk. It now reports 'Secure Boot: enabled (deployed)', and the raw efivars agree: SecureBoot=1, SetupMode=0, i.e. deployed mode, nominally full enforcement. Almost certainly a side effect of the flash restoring BIOS defaults (or of a setting toggled during the Power Supply Idle Control trip).

CONTRADICTION WORTH UNDERSTANDING: with enforcement on, an unsigned EFI binary should be refused - yet this machine is booting an unsigned Limine right now. There is no signing infrastructure at all: sbctl, sbsign, sbverify all absent, no /var/lib/sbctl, no shim-signed or preloader-signed. So enforcement is evidently not strict in this board's current Secure Boot mode, whatever bootctl reports. That matters because it decides whether an unsigned memtest.efi will chainload.

CONSEQUENCES:
  1. It may block the memtest86+ chainload (dots-dfbf). If limine reports a security violation, turn Secure Boot off in setup - joel had it off before, and nothing here depends on it: no LUKS, no crypttab, no TPM-sealed secrets, Measured OS: no.
  2. It invalidates the 'Secure Boot: disabled' premise I used earlier when assessing the v1D1 TPM firmware update. The conclusion still holds (nothing is sealed to this TPM), but the stated reason is now stale.
  3. Not suspected in the hangs - hang #5 (Sep 27 21:41:37) was post-flash so may have run with it enabled, but Secure Boot does nothing at runtime.

SEPARATE DRIFT FOUND: the deployed bootloader is Limine 12.7.0 (per bootctl's Product line) while the installed package is limine 12.9.0. The ESP binary is behind the package; 'sudo limine-install' refreshes it.
