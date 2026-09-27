---
id: dots-fe9a
title: journald retention override is ineffective
type: bug
priority: 1
created: '2026-09-24T03:01:48Z'
updated: '2026-09-27T20:27:21Z'
parent: dots-df8e
labels:
- linux
verify: systemd-analyze cat-config systemd/journald.conf | grep -E '^[^#]*SystemMaxUse' | tail -1 | grep -q '4G'
---

---
▸ 2026-09-24T03:03:04Z [claude]
Two independent reasons the /etc/systemd/journald.conf edit does nothing: (1) SystemMaxUse=26 is 26 BYTES (unsuffixed systemd size = bytes); (2) /usr/lib/systemd/journald.conf.d/00-journal-size.conf ships SystemMaxUse=50M and drop-ins are read AFTER the main file, so they win. cat-config shows =26 at line 28, =50M at line 55. Confirmed empirically: journalctl --disk-usage still ~48M. Fix = /etc/systemd/journald.conf.d/10-local.conf (sorts after 00-).

---
▸ 2026-09-24T03:03:15Z [claude]
Needs sudo: create /etc/systemd/journald.conf.d/10-local.conf with SystemMaxUse=4G, revert the SystemMaxUse=26 hand-edit in journald.conf, restart systemd-journald. Commands in docs/idle-hardlock-notes.md.

---
▸ 2026-09-27T20:27:08Z [claude]
Done. /etc/systemd/journald.conf.d/10-local.conf installed with SystemMaxUse=4G; cat-config confirms it overrides the vendor 50M (50M at line 55, 4G at line 59, last wins). Disk usage 1.8G, and retention went from 1 boot to 9 (Sep 22 -> Sep 27). This directly enabled dots-df8e's two-hang discovery.

---
▸ 2026-09-27T20:27:08Z [Joel Webber]
verify: `systemd-analyze cat-config systemd/journald.conf | grep -E '^[^#]*SystemMaxUse' | tail -1 | grep -q '4G'` -> PASS (exit 0)
