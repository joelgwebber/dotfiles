---
id: dots-d532
title: Enable a post-mortem capture path for hard locks
type: task
priority: 2
created: '2026-09-24T03:01:49Z'
updated: '2026-09-24T03:03:15Z'
parent: dots-df8e
labels:
- linux
needs: human
---

---
▸ 2026-09-24T03:03:04Z [claude]
Nothing can currently record a hard lock: nmi_watchdog=0, watchdog=0, hardlockup_panic=0, panic=0, panic_on_oops=0, no /dev/watchdog. All because 'nowatchdog' is on the cmdline - which disables the very NMI hard-lockup detector that would catch this. Kernel HAS the machinery: CONFIG_HARDLOCKUP_DETECTOR{,_PERF}=y, CONFIG_EFI_VARS_PSTORE=y (default-disabled, needs efi_pstore.pstore_disable=0), CONFIG_PSTORE_RAM=m, CONFIG_NETCONSOLE=m. No ACPI ERST/BERT tables.

---
▸ 2026-09-24T03:03:15Z [claude]
Needs sudo + a reboot: drop 'nowatchdog' (and probably 'quiet') from KERNEL_CMDLINE in /etc/default/limine, add efi_pstore.pstore_disable=0, run limine-update, add /etc/sysctl.d/99-lockup.conf. Decision for you: EFI-NVRAM pstore vs ramoops vs netconsole.
