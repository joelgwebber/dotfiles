---
id: dots-b19e
title: Migrate dotfiles from hand-rolled symlinks to chezmoi
type: task
priority: 1
created: '2026-09-13T18:03:58Z'
updated: '2026-09-13T18:20:38Z'
---

Replace the hand-maintained symlink farm (README 'Symlinks' section) with chezmoi management.

Audit of current state (2026-09-13):
- chezmoi v2.72.1 installed, ZERO state: no ~/.local/share/chezmoi, no chezmoi.toml, nothing managed.
- 8 hand-made symlinks; 2 BROKEN: ~/.tmux.conf -> config/tmux/ (dir does not exist), ~/.claude/skills -> config/claude/skills (does not exist; repo .claude/skills is empty).
- DRIFT: ~/.claude/settings.json is a real file, not a symlink, and has diverged hard from repo config/claude/settings.json. Live has span hook-dispatcher hooks + tui:fullscreen; repo has permissions/statusLine/enabledPlugins. Needs a merge decision, not a blind overwrite.
- UNMANAGED entirely: ~/.zshrc, ~/.zshenv, ~/.gitconfig, ~/.config/git/ignore.
- SECRETS: ~/.s3kr1tz.sh (API keys) sourced by .zshrc, deliberately outside the repo.
- Non-dotfile payload in repo: fonts/ (git-lfs, ~40 otf), config/sieve/ (server-side mail filters), bin/bw-cleanup, config/serena/logs.
- Machine-variant configs already split by hand: kitty.linux.conf / kitty.macos.conf; .zshrc carries work-specific (fullstory) blocks -> template candidates.
- Repo meta that must NOT become home-dir state: .yaks/, README.md, AGENTS.md, CLAUDE.md, notes.md, LICENSE.
- Working tree dirty at audit time: config/claude/settings.json, config/nvim/init.lua (+4 more since partially reverted).

---
▸ 2026-09-13T18:14:39Z [Joel Webber]
DECISIONS (user, 2026-09-13):
1. Source layout: keep ~/dotfiles repo, add .chezmoiroot containing 'home'. Repo meta (.yaks, README, notes.md, LICENSE, config/sieve, bin) stays at root, outside chezmoi's view.
2. Edit model: managed copies EVERYWHERE. No symlink_ prefixes. The symlink farm dies completely.
3. Secrets: ~/.s3kr1tz.sh stays UNMANAGED. Repo is PUBLIC (verified via gh: isPrivate=false), so no ciphertext of live API keys goes in it. Accepted cost: that file does not travel to new machines.
4. Scope: all four areas - (a) the 6 working symlinks + resolve the 2 broken, (b) shell+git configs incl. templating the FullStory/Android blocks, (c) Claude settings merge, (d) fonts -> ~/Library/Fonts.

Rejected: age encryption (public repo), Bitwarden template (bw is installed, but vault-unlock friction not worth it for a quick hack), making the repo private.

---
▸ 2026-09-13T18:20:38Z [Joel Webber]
DONE. Committed as 5f9e7eb (migration) on top of d6b444b (drift checkpoint).

Result: zero symlinks from $HOME into this repo. chezmoi manages 115 entries; 'chezmoi status' is clean.

Verified post-apply:
- interactive zsh starts clean; EDITOR=nvim (proves ~/.shared.sh sourcing), FS_SKIP_COMP=1 (work template branch), fsdev on PATH
- nvim --headless loads, lazy.nvim resolves
- ~/.serena runtime data (348M language_servers + 1.7M logs) relocated out of the repo intact
- 42 Monaspace fonts actually installed to ~/Library/Fonts for the first time; the 9 pre-existing fonts untouched
- ~/.claude/settings.json is the lossless union: 12 top-level keys, 10 hook events, nothing dropped from either fork
- credential sweep over staged files clean; s3kr1tz never was tracked

Backup of pre-migration state (live files, symlink map, uncommitted patch, runtime data) at:
/private/tmp/claude-502/-Users-joel/05874c0a-8a4e-4167-9a17-6a513592ecf0/scratchpad/pre-chezmoi-backup

Spun off: dots-2260 (tmux, needs human), dots-c09d (AGENTS.md bd->yaks), dots-1c34 ('time' in brew eval), dots-e225 (bin/bw-cleanup uninstalled).
