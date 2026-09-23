# dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). This repo is **public** — no secrets, encrypted or otherwise.

## Layout

`.chezmoiroot` points chezmoi at `home/`, so only that subtree becomes home-directory state.
Everything else here is repo material chezmoi never looks at.

```
home/            <- chezmoi source state (the only part that lands in ~)
  dot_zshrc.tmpl   -> ~/.zshrc        (templated: OS + work machine)
  dot_shared.sh    -> ~/.shared.sh
  dot_vimrc        -> ~/.vimrc
  dot_gitconfig    -> ~/.gitconfig
  dot_config/      -> ~/.config/{fish,nvim,kitty,zed,git}
  dot_claude/      -> ~/.claude/settings.json
  dot_local/bin/   -> ~/.local/bin  (on PATH via .shared.sh)
docs/            <- notes, not config
fonts/           <- checked in, but installed by hand; chezmoi never places these
sieve/           <- server-side mail filters, deployed by hand
.yaks/           <- task tracker
```

Source-name prefixes are chezmoi's: `dot_` becomes a leading `.`, `.tmpl` marks a template.
Note that files literally starting with `.` inside `home/` are **ignored** by chezmoi (except
`.chezmoi*`), which is why `~/.config/nvim/.stylua.toml` is stored as `dot_stylua.toml`.

## Shells

fish is the login shell on both machines. zsh is kept fully working as a fallback,
so anything shared has to survive in both.

```
~/.config/fish/
  conf.d/00-path.fish    PATH, Homebrew, bun, pnpm    } sourced for EVERY fish,
  conf.d/10-env.fish     EDITOR, ls/ll/grep aliases   } interactive or not
  conf.d/20-tools.fish   pyenv, direnv
  conf.d/30-work.fish    FullStory env (work machines only, templated)
  config.fish            vi bindings + the interactive-only loaders
  functions/             fish_prompt, _prompt_path, load-secrets, load-work-env
```

Two bridges exist because fish can't source POSIX shell:

- **`load-secrets`** parses `~/.s3kr1tz.sh`. That file stays POSIX `export K=V` so zsh
  can still source it directly and there's only ever one copy of the keys on disk.
- **`load-work-env`** runs `~/.fsprofile` in bash and imports the resulting environment.
  It's FullStory-managed (`### DO NOT EDIT ###`) bash that sources more bash, so it can't
  be ported — only imported. PATH is deliberately excluded from the import so it can't
  clobber what `00-path.fish` built. The aliases `environment.inc` defines don't survive
  an env import and are re-declared in `30-work.fish`.

Both loaders run only in interactive shells, matching what `.zshrc` did. Scripts that
need them can call either by name. PATH and `EDITOR`, by contrast, now apply to every
fish — under zsh they only existed interactively.

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
| symlink into a source repo | `yaks*` | yes, as relative symlinks |

Installed skills are tracked in `.skill-lock.json` by source + folder hash, so
syncing the 5KB lock reproduces all eleven of them with `npx skills update`.
Tracking their files instead would fight that updater, which owns them.

The internal ones stay local because **this repo is public** and they document
unreleased work (`fullstorydev/sightmap` is a private repo) plus a staging hostname.
They're listed in `home/.chezmoiignore` so a stray `chezmoi add -r ~/.agents` can't
sweep them in.

The `yaks*` entries are symlinks into the dev checkout at `~/src/rs/yaks`. Their
sources use chezmoi's `symlink_` prefix, where the source file's *contents* are the
link target — kept **relative** (`../../src/rs/yaks/skills/yaks`) so they resolve on
any machine with that checkout, rather than baking in `/Users/joel`.

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
`.zshrc`.

Then recreate `~/.s3kr1tz.sh` by hand (see below) — it is deliberately not in this repo.

## Daily use

```sh
chezmoi edit ~/.zshrc     # edit source, not the target
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
`.zshrc` sources it only if present.

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
