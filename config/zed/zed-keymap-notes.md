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

### Principle: one Workspace baseline + targeted overrides

The pane-nav scheme is a single baseline block scoped to
`(Workspace && !Editor) || (vim_mode == normal && !VimWaiting && !menu)`, plus
small override blocks only for the contexts that genuinely need different
behavior. Earlier iterations repeated the same eight bindings across
ImageViewer/ProjectPanel/GitPanel/Editor blocks; the predicate above subsumes
all of those — Markdown preview, SVG, CSV, image viewer, project/git panels,
project search results, git diffs all hit it for free.

Why `Editor` is excluded from the baseline (and routed through the vim-normal
predicate instead):
- `ctrl-h` in vim insert mode must remain backspace.
- Vim normal mode is where pane nav actually wants to be active in an editor;
  the second disjunct catches that without affecting insert mode.

Why `Terminal` still needs its own override block (despite Workspace
inheritance applying):
- `ctrl-hjkl` would otherwise be forwarded to the PTY as raw control chars.
- `ctrl-arrows` needs `vim::ResizePane*` actions directly because the
  terminal swallows `SendKeystrokes` before it reaches vim.
- `ctrl-shift-hjkl` and `ctrl-{`/`ctrl-}` do inherit from the baseline; the
  Terminal block keeps them commented out as a tripwire in case a regression
  makes them stop working.

ProjectPanel/GitPanel blocks now only carry their context-specific extras
(`q` to dismiss the dock, `h`/`l` to collapse/expand the git tree) — pane
nav itself is inherited.

### Bindings

| Keys | Action | Notes |
|------|--------|-------|
| `ctrl-h/j/k/l` | `workspace::ActivatePane*` | Move focus among panes |
| `ctrl-arrows` | resize panes | Baseline uses `SendKeystrokes` (`10 ctrl-w </>`, `5 ctrl-w +/-`); Terminal override uses `vim::ResizePane*` |
| `ctrl-shift-h/j/k/l` | `workspace::MoveItemToPaneInDirection` | Move tab to pane in direction |
| `ctrl-{` / `ctrl-}` | `pane::SwapItemLeft/Right` | Reorder tab within pane. `ctrl-shift-[/]` is encoded as `ctrl-{`/`ctrl-}` because Zed only preserves `shift` for ASCII letters |
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
| (n/a) | `space a a` | `agent::ToggleFocus` (focus the AI agent panel; opens it if hidden) |
| (n/a) | `space a t` | `multi_workspace::ToggleWorkspaceSidebar` ([t]hreads sidebar) |
| (n/a) | `space a s` | `agents_sidebar::ToggleThreadSwitcher` (thread [s]witcher) |

GitPanel-specific: `h` / `l` aliased to `left` / `right` for tree collapse/expand,
matching nvim-tree muscle memory.

**Gaps:**
- `<leader>gB` (ToggleGitBlame) not bound.
- LazyGit integration replaced by Zed's native git panel.
- `<leader>/` toggle comments not bound (collides with buffer search).

## Agent panel (ACP threads)

Bindings for scrolling the conversation when using ACP agents (claude-acp via
`agent_servers`). Zed's native (non-ACP) agent uses a different context tree
and these don't apply.

`AcpThread` is the conversation pane; the composer is an `Editor` descendant
of `AcpThread` (its full context is `AcpThread > Editor`).

### Strategy: scroll without focus changes

Zed exposes real `agent::ScrollOutput*` actions and handles them in **both**
the conversation pane and the composer's editor. So you can scroll the thread
while still typing in the composer — focus never has to change.

### Principle: modifier-only bindings, inherit-then-override

An earlier iteration also bound bare keys (`j`/`k`/`g g`/`G`/`[[`/`]]`) under
`AcpThread && !Editor` so the conversation pane could be navigated like a vim
buffer. That worked but added complexity: you had to gate every bare-key
binding to keep it out of the composer, and one binding could only ever serve
one of the two surfaces.

The current scheme drops bare keys entirely. Every action is modifier-keyed
(`ctrl-*`), bound on plain `AcpThread`, and inherited into `AcpThread > Editor`
unless an Editor default outranks it. That gives one set of bindings that
works identically whether the conversation pane or the composer is focused —
no context gating required — and the override block becomes a minimal patch
list of Editor defaults to reclaim.

Defaults that the composer's Editor wins on specificity, and therefore need
re-binding on `AcpThread > Editor`:

| Key | Conflict (Zed default in `AcpThread > Editor`) |
|-----|-----------------------------------------------|
| `ctrl-d` | `editor::Delete` |
| `ctrl-y` | `editor::KillRingYank` |
| `ctrl-e` | `editor::MoveToEndOfLine` |
| `ctrl-u` | `editor::DeleteToBeginningOfLine` (vim insert-mode default) |
| `ctrl-shift-d` | `git::Diff` (bound on `AcpThread > Editor` itself) |

`ctrl-shift-u` and `ctrl-{` / `ctrl-}` have no conflicting default — they
inherit cleanly from `AcpThread` with no override entry.

### Bindings

| Context | Keys | Action |
|---------|------|--------|
| `AcpThread` (inherited into composer except where Editor overrides) | `ctrl-u` / `ctrl-d` | page up / down |
| | `ctrl-y` / `ctrl-e` | line up / down (vim-style) |
| | `ctrl-shift-u` / `ctrl-shift-d` | top / bottom |
| | `ctrl-{` / `ctrl-}` | prev / next message (`ctrl-shift-[/]`) |
| | `ctrl-j` | `agent::ToggleFocus` (return focus to composer) |
| `AcpThread > Editor` (composer — explicit overrides for Editor defaults) | `ctrl-u` / `ctrl-d` | page up / down |
| | `ctrl-y` / `ctrl-e` | line up / down |
| | `ctrl-shift-d` | bottom |

### What didn't work

- **`agent::FocusUp/Down/Left/Right`** — declared in `agent_ui::actions!`
  but **never have `on_action` handlers** anywhere in the agent_ui crate.
  Bindings to them silently no-op. Verified by grepping `on_action` across
  `agent_panel.rs`, `conversation_view.rs`, `message_editor.rs`.
- **`vim_mode == normal` predicate on `AcpThread > Editor`** — the composer
  editor doesn't expose vim mode at all. Predicate never matches.
- **`SendKeystrokes`-forwarding `pageup`/`pagedown`** — worked, but the
  forwarded keystroke also reached the editor's default handler (double-fire).
  Switching to direct action dispatch suppresses that.
- **Bare-key bindings on plain `AcpThread`** — got inherited into the
  composer and ate typing. Worked when gated to `AcpThread && !Editor`, but
  was abandoned in favor of the modifier-only scheme above.

### Gaps

- **Conversation-pane focus from the composer is approximate**. `ctrl-j` is
  bound to `agent::ToggleFocus`, which toggles between the panel and its
  primary focus handle; there's no dedicated thread ↔ composer focus action.
  Practically OK because scrolling-while-typing covers the common need.
- **No conversation-internal text search**. The thread view isn't a buffer,
  so `buffer_search::Deploy` doesn't bind. Workaround: "Open Thread as
  Markdown" from the command palette, then `space /` on the resulting buffer.
- ACP-specific: bindings live under `AcpThread`. Zed's native (non-ACP) agent
  uses `AgentPanel` (composer is `MessageEditor`) — these bindings won't fire
  there.

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
