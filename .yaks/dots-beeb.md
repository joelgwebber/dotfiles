---
id: dots-beeb
title: Manage ghostty config with chezmoi
status: shorn
type: task
priority: 3
created: '2026-10-15T02:11:21Z'
updated: '2026-10-15T02:11:40Z'
labels:
- config
verify: chezmoi verify ~/.config/ghostty && ghostty +validate-config
---

---
▸ 2026-10-15T02:11:21Z [Joel Webber]
moved: hairy -> shaving

---
▸ 2026-10-15T02:11:40Z [Joel Webber]
Live config was a 0-byte ~/.config/ghostty/config.ghostty (pure defaults). Added home/dot_config/ghostty/config.ghostty with a header comment (chezmoi skips empty sources); chezmoi apply + ghostty +validate-config OK.

---
▸ 2026-10-15T02:11:40Z [Joel Webber]
verify: `chezmoi verify ~/.config/ghostty && ghostty +validate-config` -> PASS (exit 0)

---
▸ 2026-10-15T02:11:40Z [Joel Webber]
moved: shaving -> shorn
