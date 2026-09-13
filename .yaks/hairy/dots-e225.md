---
id: dots-e225
title: bin/bw-cleanup is not installed anywhere
type: task
priority: 3
created: '2026-09-13T18:20:24Z'
updated: '2026-09-13T18:20:24Z'
---

bin/bw-cleanup (38K, executable) sits in the repo but is symlinked/copied nowhere, so it is not on PATH. shared.sh does put ~/.local/bin on PATH. If it is still wanted, move it to home/dot_local/bin/executable_bw-cleanup so chezmoi installs it; otherwise delete. Left untouched by the chezmoi migration as out of scope.
