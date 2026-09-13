---
id: dots-c09d
title: AGENTS.md still tells agents to run 'bd sync' (beads)
type: task
priority: 3
created: '2026-09-13T18:20:24Z'
updated: '2026-09-13T18:20:24Z'
---

AGENTS.md 'Landing the Plane' mandates 'bd sync' in the push sequence, but this repo moved from beads to yaks in 5b6e18a. The bd binary is not part of the current workflow, so that step silently no-ops or errors for any agent following the instructions literally. Should read 'yaks' or drop the sync step.
