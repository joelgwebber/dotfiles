---
id: dots-b19e
title: Migrate dotfiles from hand-rolled symlinks to chezmoi
type: task
priority: 1
created: '2026-09-13T18:03:58Z'
updated: '2026-09-13T18:14:39Z'
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
