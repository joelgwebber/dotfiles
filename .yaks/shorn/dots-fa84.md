---
id: dots-fa84
title: 'Post-migration cleanup: drop serena, unmanage fonts'
type: task
priority: 2
created: '2026-09-13T20:24:55Z'
updated: '2026-09-13T20:25:12Z'
---

User decisions after the chezmoi migration landed:
- .serena: not cared about, drop from management entirely.
- fonts: leave as checked-in repo files only; install manually on both machines rather than having chezmoi place them.

---
▸ 2026-09-13T20:25:12Z [Joel Webber]
Done.
- serena: git rm -r home/dot_serena. chezmoi no longer manages ~/.serena/serena_config.yml. Nothing was deleted from disk -- chezmoi never removes unmanaged files -- so ~/.serena still holds 350M of language servers + logs and the config still works. Ask separately if that should actually be deleted.
- fonts: moved home/Library/Fonts back to fonts/ at the repo root, outside .chezmoiroot, so chezmoi never places them. Removed home/.chezmoiignore (the darwin gate was its only rule). All 42 OTFs remain tracked via LFS. The copies already in ~/Library/Fonts were left installed.
