# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). This repo is **public** — no secrets, encrypted or otherwise.

## Layout

`.chezmoiroot` points chezmoi at `home/`, so only that subtree becomes home-directory state.
Everything else here is repo material chezmoi never looks at.

```
home/            <- chezmoi source state (the only part that lands in ~)
  dot_vimrc        -> ~/.vimrc
  dot_gitconfig.tmpl -> ~/.gitconfig  (templated: OS, installed helpers)
  dot_config/      -> ~/.config/{fish,nvim,kitty,ghostty,zed,git}
  dot_claude/      -> ~/.claude/settings.json
  dot_local/bin/   -> ~/.local/bin  (on PATH via fish's 00-path)
docs/            <- notes, not config
fonts/           <- checked in, but installed by hand; chezmoi never places these
sieve/           <- server-side mail filters, deployed by hand
.yaks/           <- task tracker
```

Source-name prefixes are chezmoi's: `dot_` becomes a leading `.`, `.tmpl` marks a template.
Note that files literally starting with `.` inside `home/` are **ignored** by chezmoi (except
`.chezmoi*`), which is why `~/.config/nvim/.stylua.toml` is stored as `dot_stylua.toml`.

## Shells

fish is the login shell everywhere, and the only shell this repo configures. zsh and
bash are left at whatever the OS ships.

```
~/.config/fish/
  conf.d/00-path.fish    PATH, Homebrew, bun, pnpm, nvm } sourced for EVERY fish,
  conf.d/10-env.fish     EDITOR, ls/ll/grep aliases     } interactive or not
  conf.d/20-tools.fish   pyenv, direnv
  conf.d/25-nvidia.fish  NVSHMEM library path (DGX only)
  conf.d/30-work.fish    FullStory env (work machines only, templated)
  config.fish            vi bindings + the interactive-only loaders
  functions/             fish_prompt, _prompt_path, load-secrets, load-work-env, nvwb
```

`nvwb` ports NVIDIA AI Workbench's bash wrapper (sourced from `.bashrc` by its
installer). Plain commands call the CLI directly; `activate`/`deactivate`/`open`/`close`
emit bash meant to be eval'd, so those run in the real wrapper and leave you in a bash
shell (`exit` returns to fish). It's harmless where Workbench isn't installed.

Machine differences are handled at runtime where possible (`command -q`, `test -d`), so
one file works on every box and a missing tool is skipped rather than an error. Only
the FullStory block is a chezmoi template, because it depends on a choice, not on what's
installed.

Two bridges exist because fish can't source POSIX shell:

- **`load-secrets`** parses `~/.s3kr1tz.sh`. That file stays POSIX `export K=V` so bash
  tooling can still source it directly and there's only ever one copy of the keys on disk.
- **`load-work-env`** runs `~/.fsprofile` in bash and imports the resulting environment.
  It's FullStory-managed (`### DO NOT EDIT ###`) bash that sources more bash, so it can't
  be ported — only imported. PATH is deliberately excluded from the import so it can't
  clobber what `00-path.fish` built. The aliases `environment.inc` defines don't survive
  an env import and are re-declared in `30-work.fish`.

Both loaders run only in interactive shells. Scripts that need them can call either by
name. PATH and `EDITOR`, by contrast, apply to every fish.

`FS_SKIP_COMP`/`FS_SKIP_CD`/`SKIP_FS_PS1` and `NODE_EXTRA_CA_CERTS` are set *before*
`load-work-env` runs, because `.fsprofile` and `environment.inc` check them and honour
an inherited value.

## Agent skills (`~/.agents`)

Deliberately partial. `~/.agents/skills` holds three kinds of thing, and only two
of them belong in a repo:

| kind | example | synced? |
|---|---|---|
| installed by `npx skills` | `subtext-*`, `find-skills` | **no** — reproduced from `.skill-lock.json` |
| hand-authored, generic | `changesets`, `github-stacked-prs` | yes, as files |
| hand-authored, internal | `sightkick-*`, `fsta-sightmap-browser` | **no** — see below |
| installed by `yaks skills install` | `yaks*` | **no** — bundled in the yaks binary |

Installed skills are tracked in `.skill-lock.json` by source + folder hash, so
syncing the 5KB lock reproduces all eleven of them with `npx skills update`.
Tracking their files instead would fight that updater, which owns them.

The internal ones stay local because **this repo is public** and they document
unreleased work (`fullstorydev/sightmap` is a private repo) plus a staging hostname.
They're listed in `home/.chezmoiignore` so a stray `chezmoi add -r ~/.agents` can't
sweep them in.

The `yaks*` skills ship inside the yaks binary, so `yaks skills install --user` writes
the full set (all seven, matching the installed version) and `yaks skills status` says
when they're behind. They used to be symlinks into `~/src/rs/yaks/skills/`, but yaks
moved that directory to `.agents/skills/` and the links went dead. On a machine that
still has them, replace them:

```sh
rm ~/.agents/skills/yaks ~/.agents/skills/yaks-*   # the old symlinks only
yaks skills install --user
```

Note `.skill-lock.json` carries `installedAt`/`updatedAt` timestamps and folder
hashes, so running `npx skills update` on either machine produces a real diff here.
That's expected churn, not drift.

Claude Code doesn't look in `~/.agents`, so `~/.claude` points back at it:
`~/.claude/skills` is a relative symlink to `../.agents/skills`, and
`~/.claude/CLAUDE.md` pulls in `~/.agents/AGENTS.md` with an `@` import.

## New machine

```sh
chezmoi init --source=~/dotfiles --apply https://github.com/joelgwebber/dotfiles.git
```

`--source=~/dotfiles` matters: the generated config records that path, so cloning anywhere else
leaves chezmoi pointing at a directory that doesn't exist. Init asks whether it's a work machine
and writes the answer to `~/.config/chezmoi/chezmoi.toml`, which gates the FullStory block in
fish's `30-work.fish`.

Then:

1. Install fish and make it the login shell. macOS: `brew install fish`. Linux:
   `sudo apt install fish`, or Homebrew below.
   Then: `echo $(command -v fish) | sudo tee -a /etc/shells; chsh -s $(command -v fish)`.
2. Homebrew (Linux too: `/home/linuxbrew/.linuxbrew`, which `00-path.fish` picks up),
   then `brew install direnv tree-sitter-cli`. Everything in `conf.d` skips tools that
   aren't installed, so this can come later. nvim-treesitter's `main` branch compiles
   parsers with the `tree-sitter` CLI; without it every start re-downloads them and fails.
3. `gh auth login`. Git uses gh for GitHub on every machine, so there's no token in
   `~/.git-credentials` to manage.
4. `yaks skills install --user` (see Agent skills).
5. Recreate `~/.s3kr1tz.sh` by hand (see below). It is deliberately not in this repo.

## Git identity and credentials

The default email is `jgw@pobox.com` on every machine. Any repo with a remote under
`github.com/fullstorydev` (https or ssh) also includes `~/.config/git/fullstory`, which
switches it to `joel@fullstory.com`. So the address follows the repo, not the machine:
these dotfiles commit as the personal address even from a work laptop.

Credentials: GitHub always goes through `gh auth git-credential`. Every other host
(e.g. huggingface.co) uses the OS store: the macOS keychain, libsecret where its helper
is installed, and otherwise git's plaintext `store` (`~/.git-credentials`). Ubuntu doesn't
ship a built libsecret helper.

## Daily use

```sh
chezmoi edit ~/.config/fish/config.fish   # edit source, not the target
chezmoi apply             # push source -> home
chezmoi diff              # preview what apply would change
chezmoi re-add            # pull an in-place edit back into source
chezmoi cd                # drop into the source repo to commit
```

Apps that rewrite their own config (Zed, Claude Code) edit the *target* file, not the source.
Their changes land in `~`, so run `chezmoi re-add` to bring them back, or `chezmoi diff` to see
what drifted. Under the old symlink setup those writes went straight into this repo; now they
don't, which is the point — but it does mean drift is something you pull in deliberately.

## `.s3kr1tz.sh`

Unmanaged on purpose: this repo is public, so no ciphertext of live keys goes in it.
fish's `load-secrets` reads it if present. Keep it `chmod 600`.

```sh
export OPENROUTER_API_KEY="..."
export TAVILY_API_KEY="..."
export ANTHROPIC_API_KEY="..."
export GEMINI_API_KEY="..."
export CONTEXT7_API_KEY="..."
export OPENAI_API_KEY="..."
export BRAVE_API_KEY="..."
export READECK_API_URL="..."
export READECK_API_KEY="..."
```

## MCP Servers

```sh
claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
```

## Claude Plugins

```
/plugin marketplace add joelgwebber/yaks
/plugin install yaks
```
