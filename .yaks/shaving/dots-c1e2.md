---
id: dots-c1e2
title: Update MSI MS-7D53 BIOS from 1.40 (2022)
type: task
priority: 2
created: '2026-09-24T03:01:49Z'
updated: '2026-09-27T21:14:02Z'
parent: dots-df8e
labels:
- linux
needs: human
---

---
▸ 2026-09-24T03:03:04Z [claude]
BIOS 1.40 dated 2022-09-01 on MS-7D53. No capsule path: /sys/firmware/efi/esrt absent, fwupd not installed => LVFS impossible on this board. M-FLASH from FAT32 USB is the route. Also want BIOS 'Power Supply Idle Control = Typical Current Idle' (classic Zen idle-hardlock fix, OS-invisible). Boot survives an NVRAM wipe: Boot0005 UEFI OS -> EFI/BOOT/BOOTX64.EFI is the Limine fallback.

---
▸ 2026-09-24T03:03:15Z [claude]
Needs physical action: M-FLASH from a FAT32 USB stick, plus setting Power Supply Idle Control = Typical Current Idle. Nothing I can do from the OS.

---
▸ 2026-09-27T20:27:22Z [claude]
Still open: BIOS reads 1.40 / 09/01/2022 as of Sep 27.

---
▸ 2026-09-27T20:56:29Z [claude]
Promoted: with pcie_aspm=off falsified and the NMI detector failing to catch hang #3, a platform/firmware-level freeze is now the leading theory, which makes the 4-year-old AGESA and the Power Supply Idle Control setting the most promising untried lever.

---
▸ 2026-09-27T21:14:02Z [claude]
Firmware path researched and image verified.

VERSION MAPPING: DMI reports bios_version 1.40 / date 09/01/2022. That is MSI's 7D53v14 (AGESA ComboAm4v2PI 1.2.0.7). Latest stable is 7D53v1D4, released 2026-08-21 - about twelve releases and AGESA 1.2.0.7 -> 1.2.0.12.

IMAGE (verified, not just cited):
  URL     https://download.msi.com/bos_exe/mb/7D53v1D4.zip (302 -> download-2.msi.com)
  size    18438222 bytes, Content-Type application/zip, magic PK\x03\x04
  mtime   Fri 21 Aug 2026 09:50:09 GMT (matches the published release date)
  sha256  7c23103da2295dd33c0bd7aa7e54c1a221a62a6283bb9eb5c3e2fec96d55d251
  unzip -t clean; contains 7D53v1x.txt (MSI's own notes, confirm 'V1.D4 BIOS Release', AMI, 2026/08/21) and E7D53AMS.1D4 (33554432 bytes = 32MiB ROM)
  saved to ~/Downloads/7D53v1D4.zip
  NOTE: E7D53AMS.1D4 is the filename to pick in M-FLASH; rename to MSI.ROM only for the Flash BIOS Button route.

NO fwupd/capsule path exists (no /sys/firmware/efi/esrt, fwupd not installed) - confirmed earlier. M-FLASH or the Flash BIOS Button are the only routes. This board HAS a Flash BIOS Button at the lower-left of the rear I/O with a dedicated USB port beside it (FAT32, USB 2.0 stick preferred).

TWO CHANGELOG ENTRIES DIRECTLY RELEVANT TO dots-df8e:
- v17 added 'PCIe ASPM Control'. This board's current v14 predates MSI exposing ASPM control in setup at all - notable given how much of this investigation went into pcie_aspm.
- v1B1 (AGESA 1.2.0.Cc) fixed the 'Sinkclose' SMM Lock Bypass. SMM is squarely where hang #3 points, since the NMI hard-lockup detector was armed and never fired.

TPM RISK CLEARED: v1D1 updates TPM firmware and MSI recommends a BitLocker backup first. Verified not applicable here - no /etc/crypttab entries, no LUKS devices, no systemd-cryptenroll units, Secure Boot disabled, 'Measured OS: no'. Nothing is sealed to this TPM.

No intermediate version is required per MSI's notes and the changelog history; v14 -> v1D4 direct is fine.
