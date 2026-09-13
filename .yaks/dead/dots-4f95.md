---
id: dots-4f95
title: Fonts do not install on Linux
type: task
priority: 3
created: '2026-09-13T18:33:56Z'
updated: '2026-09-13T20:25:12Z'
---

home/.chezmoiignore gates Library/Fonts to darwin, because ~/Library/Fonts is macOS-only. So on the Linux machine the 42 Monaspace OTFs are pulled into the repo (LFS) but installed nowhere. Linux wants ~/.local/share/fonts.

Not a regression -- before the chezmoi migration they were installed on NO machine -- but the deleted symlink fonts/MonaspaceArgonNF/fonts -> .local/share/fonts suggests this was attempted once.

chezmoi can't point one source at two targets, so the options are:
1. run_onchange_install-fonts.sh.tmpl that copies from {{ .chezmoi.sourceDir }}/Library/Fonts into the OS-appropriate dir and runs fc-cache on Linux. One source of truth, small script.
2. Move the source to home/dot_local/share/fonts (Linux-native) and script the macOS side instead.
3. Leave macOS-only and install fonts by hand on Linux.

Option 1 is the least duplication.

---
▸ 2026-09-13T20:25:12Z [Joel Webber]
Won't do. User: 'No worries about the font thing. Let's just leave that as checked in files, and I'll install them manually on both systems.' Fonts are now plain repo files at fonts/, outside chezmoi's view, so there is no OS-specific install path to build.
