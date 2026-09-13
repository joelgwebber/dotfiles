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
  dot_config/      -> ~/.config/{nvim,kitty,zed,git}
  dot_claude/      -> ~/.claude/settings.json
  dot_serena/      -> ~/.serena/serena_config.yml
  dot_local/bin/   -> ~/.local/bin  (on PATH via .shared.sh)
  Library/Fonts/   -> ~/Library/Fonts  (macOS only, see .chezmoiignore)
docs/            <- notes, not config
sieve/           <- server-side mail filters, deployed by hand
.yaks/           <- task tracker
```

Source-name prefixes are chezmoi's: `dot_` becomes a leading `.`, `.tmpl` marks a template.
Note that files literally starting with `.` inside `home/` are **ignored** by chezmoi (except
`.chezmoi*`), which is why `~/.config/nvim/.stylua.toml` is stored as `dot_stylua.toml`.

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
