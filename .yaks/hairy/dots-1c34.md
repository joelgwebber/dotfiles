---
id: dots-1c34
title: Odd 'time' in .zshrc brew shellenv eval
type: task
priority: 3
created: '2026-09-13T18:20:24Z'
updated: '2026-09-13T18:20:24Z'
---

home/dot_zshrc.tmpl line 1 carries: eval "time $(/opt/homebrew/bin/brew shellenv)"

The 'time' applies to only the first export statement in brew's output and prints timing to stderr on every shell start. Looks like a debugging leftover. Preserved verbatim during the chezmoi migration (migration != refactor), but worth deleting.

Fix: drop 'time ' from the eval in home/dot_zshrc.tmpl, then chezmoi apply.
