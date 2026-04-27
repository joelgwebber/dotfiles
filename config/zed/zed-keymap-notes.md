# Zed Keymap Migration Notes

Mapping nvim keybindings to Zed. See `~/.config/zed/keymap.json` for the live config.

References:
- [Zed key-bindings docs](https://zed.dev/docs/key-bindings)
- [Ethan Holz: Using Zed as a Neovim User](https://ethanholz.com/blog/using-zed-as-a-neovim-user/)
- [anuragg-p/zed-nvim keymap.json](https://github.com/anuragg-p/zed-nvim/blob/main/keymap.json)
- Source nvim config: `config/nvim/lua/config/keymaps.lua` + plugin configs

## Leader scheme

`cmd-space` is the canonical leader, working from any context. In vim normal mode,
bare `space` is aliased to `cmd-space` via `SendKeystrokes`, so muscle memory from
nvim still works. The alias is necessary because Zed's terminal and panel contexts
eat bare keystrokes before the keymap system sees them; `cmd-` keys are processed at
the OS level and reach Zed's action dispatch first.

## Pane navigation, resizing, and tab management

Per-context blocks are required for non-Editor contexts (Terminal, ImageViewer,
ProjectPanel, GitPanel) because they consume keys before the keymap system unless
explicitly overridden.

| Keys | Action | Notes |
|------|--------|-------|
| `ctrl-h/j/k/l` | `workspace::ActivatePane*` | Move focus among panes |
| `ctrl-arrows` | resize panes | Editor/Image/Panel use `SendKeystrokes` (`10 ctrl-w </>`, `5 ctrl-w +/-`); Terminal uses `vim::ResizePane*` (SendKeystrokes is consumed by PTY) |
| `ctrl-shift-h/j/k/l` | `workspace::MoveItemToPaneInDirection` | Move tab to pane in direction |
| `ctrl-{` / `ctrl-}` | `pane::SwapItemLeft/Right` | Reorder tab within pane. Note: `ctrl-shift-[/]` is encoded as `ctrl-{`/`ctrl-}` because Zed only preserves `shift` for ASCII letters |
| `q` (panels) | `workspace::ToggleLeftDock` | Dismiss project/git panels |

**Gaps:** No `<leader>==` (equalize panes) in Zed.

## Code / LSP Navigation (vim normal mode)

| Nvim | Zed Binding | Zed Action |
|------|-------------|------------|
| `gd` | `g d` | `editor::GoToDefinition` |
| `gr` | `g r` | `editor::FindAllReferences` |
| `gI` | `g I` | `editor::GoToImplementation` |
| `gt` | `g t` | `editor::GoToTypeDefinition` |
| `gD` | `g D` | `editor::GoToDeclaration` |
| `K` | `shift-k` | `editor::Hover` |

### Code Actions (leader)

| Nvim | Zed Binding | Zed Action |
|------|-------------|------------|
| `<leader>cr` | `space c r` | `editor::Rename` |
| `<leader>ca` | `space c a` | `editor::ToggleCodeActions` |
| `<leader>cf` | `space c f` | `editor::Format` |
| `<leader>co` | `space c o` | `outline::Toggle` |

**Gaps:** No `<leader>cs` (Trouble document symbols); merged into `co`.

### Diagnostics

| Nvim | Zed Binding | Zed Action |
|------|-------------|------------|
| `]d` / `[d` | `] d` / `[ d` | `editor::GoTo(Prev)Diagnostic` |
| `<leader>dd` | `space d d` | `diagnostics::Deploy` |

**Gaps:**
- No severity-filtered navigation (`]e`/`]w` for errors/warnings only).
- `<leader>dt` (Trouble todo), `<leader>ds`/`<leader>dh` (toggle diagnostics) not available.
- **Known bug** ([zed#40394](https://github.com/zed-industries/zed/issues/40394)): `GoToDiagnostic` skips `is_unnecessary` diagnostics (e.g. Rust unused-variable warnings) due to a hardcoded filter. Workaround: use diagnostics panel.

## Search / Fuzzy Finding

| Nvim | Zed Binding | Zed Action |
|------|-------------|------------|
| `<leader>sf` | `space s f` | `file_finder::Toggle` |
| `<leader>sg` | `space s g` | `pane::DeploySearch` |
| `<leader><leader>` | `space space` | `tab_switcher::ToggleAll` (all panes) |
| `<leader>/` | `space /` | `buffer_search::Deploy` |

**Gaps:**
- `<leader>sw` (grep current word) — no project-search-with-query action ([zed PR#47331](https://github.com/zed-industries/zed/pull/47331) pending). `*`/`#` work for in-buffer.
- `<leader>s/` (grep open files only) — no "open files" scope.
- `<leader>sh`/`<leader>sk`/`<leader>ss`/`<leader>sn` — Telescope-specific, no equivalents.
- `<leader>s.` / `<leader>sr` — no recents/resume picker.

## Buffer / Path

| Nvim | Zed Binding | Zed Action |
|------|-------------|------------|
| `<leader>bd` | `space w d` | `pane::CloseActiveItem` (under `w`, not `b`) |
| `<leader>by` | `space b y` | `workspace::CopyRelativePath` |
| `<leader>bY` | `space b Y` | `workspace::CopyPath` (absolute) |

**Gaps:**
- `H` / `L` for buffer cycling — not bound; relies on `space space` tab switcher instead.
- `<leader>bo` (open with OS) — not mapped.

## File Explorer / Git / AI

| Nvim | Zed Binding | Zed Action |
|------|-------------|------------|
| `<leader>e` | `space e` | `project_panel::ToggleFocus` |
| `<C-n>` | `ctrl-n` | `pane::RevealInProjectPanel` |
| `<leader>gg` | `space g g` | `git_panel::ToggleFocus` (not LazyGit; Zed's git panel) |
| `<leader>gb` | `space g b` | `git::Branch` (branch picker, not blame) |
| (n/a) | `space a a` | `agent::Toggle` (Zed AI agent panel) |

GitPanel-specific: `h` / `l` aliased to `left` / `right` for tree collapse/expand,
matching nvim-tree muscle memory.

**Gaps:**
- `<leader>gB` (ToggleGitBlame) not bound.
- LazyGit integration replaced by Zed's native git panel.
- `<leader>/` toggle comments not bound (collides with buffer search).

## Terminal

| Nvim | Zed Binding | Zed Action |
|------|-------------|------------|
| `<C-,>` | `ctrl-,` | `workspace::ToggleBottomDock` |
| `<leader>tt` | `space t t` | `terminal_panel::ToggleFocus` |
| `<leader>th` | `space t h` | `workspace::ToggleBottomDock` |
| `<leader>tf` | `space t f` | `workspace::NewCenterTerminal` (float) |
| `<leader>tn` | `space t n` | `workspace::NewTerminal` |
| `<leader>tr` | `space t r` | `terminal_panel::RenameTerminal` |
| (Zed default) | `ctrl-space` | `terminal::ToggleViMode` (instead of awkward `ctrl-shift-space`) |

**Known issue:** When terminal is in vi/select mode, system `cmd-`` ` (window cycling)
sometimes gets eaten by the terminal's vi handler. Tried binding it explicitly to
`workspace::ActivatePreviousWindow` but that only toggles between two windows and made
window cycling worse — reverted. Probably a Zed bug where the vi handler intercepts
cmd-modified keystrokes before action dispatch.

## Universal

| Keys | Action | Notes |
|------|--------|-------|
| `cmd-;` | `command_palette::Toggle` | Universal escape hatch from any context. Overridden in Editor too because default toggles line numbers |

## Not Mapped (no Zed equivalent)

- **REPL** (`<leader>r*`) — no integrated REPL
- **Xcodebuild** (`<leader>x*`) — platform-specific nvim plugin
- **SuperCollider** (`<leader>mS*`)
- **Hex editor** (`<leader>hx`)
- **JQ/FQ playground** (`<leader>jq`, `<leader>fq`)
- **CSV view**
- **Image preview** (`<leader>i*`)
- **Neotest details** — Zed's test runner is more basic
- **Window equalize** (`<leader>=*`)
- **Copilot suggestion cycling** (`<C-=>`/`<C-->`) — Zed handles inline completions differently
- **Toggle comments via `<leader>/`** — Zed default is `cmd-/`; leader slash is taken by buffer search
- **Line move (`<C-S-j/k>`)** — slot reused for `MoveItemToPaneInDirection`

## Quirks worth remembering

- **Space alias trick**: bare space in `VimControl` aliases to `cmd-space`, so leader bindings live under one canonical `Workspace` block.
- **`ctrl-shift-[/]` syntax**: Zed only preserves shift for ASCII letters. For punctuation, use the shifted character: `ctrl-{` / `ctrl-}`.
- **GitPanel always reports as "editing"**: don't qualify GitPanel context with `not_editing` — it'll never match.
- **Terminal eats SendKeystrokes**: any binding that synthesizes vim ex commands won't reach vim from inside Terminal context. Bind real actions instead (e.g., `vim::ResizePane*`).
- **which-key dismissal**: bare `space` bound to `vim::WrappingRight` was dismissing the popup; the alias to `cmd-space` works around it.
