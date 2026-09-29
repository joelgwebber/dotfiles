---
id: dots-5c4f
title: Secure Boot silently re-enabled by the BIOS flash
type: bug
priority: 2
created: '2026-09-28T21:18:14Z'
updated: '2026-09-29T03:07:28Z'
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

---
▸ 2026-09-29T03:07:28Z [claude]
CONFIRMED AS THE LIKELY CAUSE of the memtest panic, and the earlier contradiction is resolved.

Secure Boot here is genuinely armed: db is populated (8458 bytes, contains 'Microsoft Windows Production PCA 2011' among others), KEK 3888 bytes, PK 821 bytes, SecureBoot=1, SetupMode=0.

Documented precedent - omacom/omarchy issue 12045: on MSI boards with AMI Aptio firmware, Limine's EFI chainload panics with exactly 'PANIC: efi: LoadImage failure (0x800000000000000f)' = EFI_ACCESS_DENIED, ONLY when Secure Boot is enabled; with it disabled the same binary boots. Tracked as MSI firmware bug FQ0001: the firmware cannot reliably execute non-factory-signed .efi binaries through LoadImage() while Secure Boot is active. That report is a 600-series board and this is X570S, so FQ0001 may not apply verbatim, but the generic mechanism does: memtest.efi is unsigned and LoadImage enforces platform policy.

WHY UNSIGNED LIMINE BOOTS BUT MEMTEST DOES NOT - enforcement asymmetry. Limine is loaded by the firmware's own boot manager (BootCurrent -> EFI/BOOT/BOOTX64.EFI), which this firmware evidently does not police. When Limine then calls LoadImage() to chainload memtest, that call DOES go through image-loading policy and is refused. So my earlier inference that 'enforcement is evidently lax' was only true of the firmware's boot path, not of runtime LoadImage.

FIX: disable Secure Boot in setup. It costs nothing here - no LUKS, no crypttab, no TPM-sealed secrets, Measured OS: no - it was disabled before the flash anyway, and it removes a variable from dots-df8e.

STATUS CODE DECODE for reading the panic:
  0x800000000000000f EFI_ACCESS_DENIED      -> Secure Boot policy refused it
  0x800000000000001a EFI_SECURITY_VIOLATION -> Secure Boot validation failed
  0x8000000000000002 EFI_INVALID_PARAMETER  -> firmware LoadImage quirk (also reported on older UEFI)
  0x800000000000000e EFI_NOT_FOUND          -> path wrong in limine.conf
  0x8000000000000003 EFI_UNSUPPORTED        -> wrong arch/format
