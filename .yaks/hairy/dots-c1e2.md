---
id: dots-c1e2
title: Update MSI MS-7D53 BIOS from 1.40 (2022)
type: task
priority: 2
created: '2026-09-24T03:01:49Z'
updated: '2026-09-27T20:56:29Z'
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
