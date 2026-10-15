---
id: dots-344c
title: 'Ghostty: document keybinds, ctrl+shift+[/] for tabs'
status: shorn
type: task
priority: 3
created: '2026-10-15T02:21:15Z'
updated: '2026-10-15T02:39:26Z'
labels:
- config
verify: ghostty +validate-config && ghostty +list-keybinds | grep -q "ctrl+shift+\[=previous_tab" && ! ghostty +list-keybinds | grep -qE "^keybind = ctrl\+page_"
---

---
▸ 2026-10-15T02:21:15Z [Joel Webber]
moved: hairy -> shaving

---
▸ 2026-10-15T02:21:48Z [Joel Webber]
Documented Linux default keybinds (ghostty +list-keybinds --default) as grouped comments; bound ctrl+shift+[/] to previous/next_tab; unbound ctrl+page_up/down. validate-config OK; +list-keybinds shows the new binds and no ctrl+page_* tab binds. Pending: live keypress check by Joel (shift+[ yields '{' on US layout).

---
▸ 2026-10-15T02:21:48Z [Joel Webber]
verify: `ghostty +validate-config && ghostty +list-keybinds | grep -q "ctrl+shift+\[=previous_tab" && ! ghostty +list-keybinds | grep -qE "^keybind = ctrl\+page_"` -> PASS (exit 0)

---
▸ 2026-10-15T02:39:26Z [Joel Webber]
Joel confirmed live: ctrl+shift+[/] switch tabs after reload (char-based trigger works, no need for bracket_left).

---
▸ 2026-10-15T02:39:26Z [Joel Webber]
verify: `ghostty +validate-config && ghostty +list-keybinds | grep -q "ctrl+shift+\[=previous_tab" && ! ghostty +list-keybinds | grep -qE "^keybind = ctrl\+page_"` -> PASS (exit 0)

---
▸ 2026-10-15T02:39:26Z [Joel Webber]
moved: shaving -> shorn
