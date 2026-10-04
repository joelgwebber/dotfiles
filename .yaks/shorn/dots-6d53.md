---
id: dots-6d53
title: git credential helpers broken on Linux after chezmoi sync from mac
type: bug
priority: 2
created: '2026-10-04T15:34:05Z'
updated: '2026-10-04T15:34:29Z'
labels:
- linux
- git
- chezmoi
verify: printf 'protocol=https\nhost=github.com\n\n' | GIT_TERMINAL_PROMPT=0 git credential fill >/dev/null
---

~/.gitconfig had macOS-only helpers (osxkeychain, /opt/homebrew/bin/gh) after syncing from the laptop. GitHub HTTPS auth fails: the gh helper path doesn't exist and the empty helper= reset drops the fallback.

---
▸ 2026-10-04T15:34:19Z [Joel Webber]
verify: `printf 'protocol=https\nhost=github.com\n\n' | GIT_TERMINAL_PROMPT=0 git credential fill >/dev/null` -> PASS (exit 0)

---
▸ 2026-10-04T15:34:29Z [Joel Webber]
Cause: on the Mac, `gh auth setup-git` writes `!/opt/homebrew/bin/gh auth git-credential` (absolute path) plus `helper = osxkeychain`, and that got captured into the plain (non-template) home/dot_gitconfig. On Linux, /opt/homebrew/bin/gh does not exist, and the empty `helper =` reset clears the libsecret fallback, so GitHub HTTPS had no working helper at all. A local hand-edit had fixed only the osxkeychain line.

Fix: home/dot_gitconfig -> dot_gitconfig.tmpl. The keychain helper branches on .chezmoi.os, and the gh path is resolved per machine with `lookPath "gh"` (the block is omitted if gh is missing). Applied here; verify passes.

Prevention: do not re-run `gh auth setup-git` on either machine, since it rewrites ~/.gitconfig with an absolute path. If you do, `chezmoi re-add` skips template files, so it will not sneak back into the source; use `chezmoi diff` to spot it.
