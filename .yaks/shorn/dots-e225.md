---
id: dots-e225
title: bin/bw-cleanup is not installed anywhere
type: task
priority: 3
created: '2026-09-13T18:20:24Z'
updated: '2026-09-13T18:31:05Z'
---

bin/bw-cleanup (38K, executable) sits in the repo but is symlinked/copied nowhere, so it is not on PATH. shared.sh does put ~/.local/bin on PATH. If it is still wanted, move it to home/dot_local/bin/executable_bw-cleanup so chezmoi installs it; otherwise delete. Left untouched by the chezmoi migration as out of scope.

---
▸ 2026-09-13T18:28:56Z [Joel Webber]
Please go ahead and move it.

---
▸ 2026-09-13T18:31:05Z [Joel Webber]
Moved bin/bw-cleanup -> home/dot_local/bin/executable_bw-cleanup; repo-root bin/ dissolved.

It is a python3 script (not a binary, as the 38K size suggested), so the shebang carries it. chezmoi's executable_ prefix installs it 0755 at ~/.local/bin/bw-cleanup, which .shared.sh already puts on PATH.

Verified: resolves as bw-cleanup in a fresh interactive zsh, and --help runs.
