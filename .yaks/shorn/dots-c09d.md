---
id: dots-c09d
title: AGENTS.md still tells agents to run 'bd sync' (beads)
type: task
priority: 3
created: '2026-09-13T18:20:24Z'
updated: '2026-09-13T18:31:05Z'
---

AGENTS.md 'Landing the Plane' mandates 'bd sync' in the push sequence, but this repo moved from beads to yaks in 5b6e18a. The bd binary is not part of the current workflow, so that step silently no-ops or errors for any agent following the instructions literally. Should read 'yaks' or drop the sync step.

---
▸ 2026-09-13T18:27:58Z [Joel Webber]
Definitely drop that comment!

---
▸ 2026-09-13T18:31:05Z [Joel Webber]
Dropped the 'bd sync' line from AGENTS.md's push sequence.

Also removed two related beads leftovers found while doing it:
- .gitattributes carried a '.beads/issues.jsonl merge=beads' rule (plus comment) for a directory that does not exist
- .git/config defined the matching merge driver 'bd merge %A %O %A %B', pointing at a binary no longer installed
Both inert, both now gone. The LFS rule for *.otf is untouched and verified still active.
