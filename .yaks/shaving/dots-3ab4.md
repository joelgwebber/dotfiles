---
id: dots-3ab4
title: Standardize on fish as the login shell
type: task
priority: 1
created: '2026-09-13T20:26:05Z'
updated: '2026-09-13T20:33:51Z'
---

User has chsh'd to fish on this Mac (fish 4.9.3, /opt/homebrew/bin/fish, already in /etc/shells) and already runs fish on the Linux box. Port the zsh config and clean up the accumulated mess in the process.

CURRENT STATE (Mac, surveyed 2026-09-13):
- ~/.config/fish is VIRGIN: default 87-byte config.fish scaffold, empty conf.d/ functions/ completions/, no fish_variables. Dir mode is 700 -> needs chezmoi's private_ prefix.
- $SHELL still reads /bin/zsh in running sessions; chsh only affects new logins.
- No fisher, no bass installed.
- Linux box already runs fish with a config that is NOT in this repo and cannot be seen from here.

WHAT HAS TO PORT:
home/dot_shared.sh -> fish
  set -o vi / bindkey -v      => fish_vi_key_bindings
  EDITOR/GIT_EDITOR=nvim      => set -gx
  aliases ls/ll/grep          => --color is fine, macOS BSD ls does support it (verified)
  PS1 '[host] path > '        => must become a fish_prompt function
  PATH ~/.local/bin ~/go/bin ~/.cargo/bin => fish_add_path
  pyenv init -                => pyenv init - fish | source

home/dot_zshrc.tmpl -> fish
  brew shellenv               => brew shellenv fish | source
  pyenv virtualenv-init -     => needs the fish variant
  direnv hook zsh             => direnv hook fish | source
  bindkey ^R history search   => fish has this natively
  bun / antigravity / pnpm / depot_tools PATH => fish_add_path
  NODE_EXTRA_CA_CERTS, FS_SKIP_* => set -gx
  logcatfs / logcatc aliases  => fish functions

TWO HARD PARTS:
1. ~/.fsprofile is '### DO NOT EDIT ###' FullStory-managed bash. It sources $FSDEV_HOME/environment.inc, which is #!/bin/bash: sets env vars, defines aliases (fs, fsdev, terraform, tofu, kubectl), calls ulimit, and does git-config side effects. fish cannot source any of it.
   Mitigating: the user sets FS_SKIP_COMP/FS_SKIP_CD/SKIP_FS_PS1=1, so completions.inc, the auto-cd, and ps1.inc are all already skipped -- only environment.inc and /Users/joel/secrets.sh really matter.
   Options: bass plugin; or a fish function that diffs 'bash -c "source ~/.fsprofile; env"' and imports the delta, plus hand-written fish wrappers for the 5 aliases; or keep a zsh subshell for work tasks.

2. ~/.s3kr1tz.sh is POSIX 'export K="V"' lines -- fish cannot source it. It has grown well past the README's list (now also GitHub PAT, FullStory + Subtext keys). .fsprofile additionally sources a second secrets file, /Users/joel/secrets.sh.
   Options: convert to fish 'set -gx'; keep POSIX and parse it from fish; or move to a shell-neutral K=V file both can read.

BLOCKING: need the Linux fish config before designing this, or the two machines will diverge again immediately.

---
▸ 2026-09-13T20:33:35Z [Joel Webber]
Mac side done and verified. fish config built fresh from the zsh port; Linux reconciliation still outstanding (user's choice -- they'll diff their existing Linux fish config against this).

Layout: home/dot_config/private_fish/ (private_ preserves fish's 0700 dir mode).
  conf.d/00-path 10-env 20-tools  -> unconditional
  conf.d/30-work.fish.tmpl        -> gated on .work
  config.fish                     -> vi bindings + interactive-only loaders
  functions/                      -> fish_prompt, _prompt_path, load-secrets, load-work-env

Verified on this machine:
- prompt is character-identical to the zsh PS1 across 6 paths incl. edge cases / and ~. fish's prompt_pwd could NOT do this (--dir-length=0 prints the path in full instead of eliding the head), so _prompt_path reimplements zsh's %(4~|.../%3~|%~).
- EDITOR/GIT_EDITOR set, fish_vi_key_bindings active, pyenv (PYENV_SHELL=fish) and direnv hooks installed.
- PATH carries .local/bin, .cargo/bin, homebrew, bun.
- all 4 spot-checked API keys load with non-empty values via load-secrets.
- work env imports from bash: MN_HOME, FSDEV_HOME, FS_HOME, FS_LOCAL, USE_GKE_GCLOUD_AUTH_PLUGIN. NODE_EXTRA_CA_CERTS correctly keeps the user's mkcert path rather than environment.inc's .localssl default -- the set-before-import ordering works.
- gating confirmed under a CLEAN env (env -i): non-interactive fish loads NEITHER secrets nor work env, but still gets PATH/EDITOR. An earlier test appeared to leak only because the test shell had inherited those vars.
- startup 0.39-0.58s vs zsh 0.38-0.71s -- no regression.
- zsh still fully works: EDITOR, FS_HOME, and keys all present.

DEVIATION from the stated answers, flagged to the user: 'keep both shells fully working' and 'convert secrets to fish set -gx' are contradictory -- fish syntax would leave zsh with no keys. Kept ~/.s3kr1tz.sh POSIX as the single source of truth and parse it from fish, rather than putting a second copy of live keys on disk. One-line flip if zsh is later retired.
