---
id: dots-2c1b
title: ~/.gitconfig hardcodes macOS credential helpers
type: bug
priority: 2
created: '2026-09-24T03:04:38Z'
updated: '2026-09-24T03:04:38Z'
labels:
- git
---

---
▸ 2026-09-24T03:04:38Z [claude]
Blocks 'git push' on Linux. ~/.gitconfig sets credential.helper=osxkeychain and credential.https://github.com.helper=!/opt/homebrew/bin/gh auth git-credential; that path does not exist here, so pushes fail with 'could not read Username'. gh IS installed at /usr/bin/gh and authenticated (joelgwebber, repo scope). Worked around for one push with 'git -c credential.helper= -c credential.https://github.com.helper=!/usr/bin/gh ...'. Real fix: make home/dot_gitconfig a chezmoi .tmpl with an OS conditional (it is currently untemplated, unlike dot_zshrc.tmpl). Not done unilaterally - applying it rewrites the live ~/.gitconfig. Related: dots-b19e.
