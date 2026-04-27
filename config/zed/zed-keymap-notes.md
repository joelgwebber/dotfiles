# Zed Keymap Migration Notes

Mapping nvim keybindings to Zed, cluster by cluster. Leader is `space` in both.

References:
- [Zed key-bindings docs](https://zed.dev/docs/key-bindings)
- [Ethan Holz: Using Zed as a Neovim User](https://ethanholz.com/blog/using-zed-as-a-neovim-user/)
- [anuragg-p/zed-nvim keymap.json](https://github.com/anuragg-p/zed-nvim/blob/main/keymap.json)
- Source nvim config: `config/nvim/lua/config/keymaps.lua` + plugin configs

## Cluster 1: Pane Navigation & Splits (done)

| Nvim | Zed Binding | Zed Action | Notes |
|------|-------------|------------|-------|
| `<C-h/j/k/l>` | `ctrl-h/j/k/l` | `workspace::ActivatePane*` | Also bound in Terminal context |
| `<C-Left/Right>` | `ctrl-left/right` | `SendKeystrokes 4 ctrl-w </>` | Count prefix for larger step |
| `<C-Up/Down>` | `ctrl-up/down` | `SendKeystrokes 2 ctrl-w +/-` | Count prefix for larger step |
| `<leader>ws` | `space w s` | `pane::SplitDown` | |
| `<leader>wv` | `space w v` | `pane::SplitRight` | |
| `<leader>wd` | `space w d` | `pane::CloseActiveItem` | |
| `<C-S-l>` (terminal) | `ctrl-shift-l` | `terminal::SendKeystroke ctrl-l` | Clear screen only; no scrollback clear in Zed |

**Gaps:** No `<leader>==` equivalent (equalize panes) in Zed.

## Cluster 2: Code / LSP Navigation (done)

### Goto

| Nvim | Zed Binding | Zed Action | Notes |
|------|-------------|------------|-------|
| `gd` | `g d` | `editor::GoToDefinition` | Also a Zed vim default |
| `gr` | `g r` | `editor::FindAllReferences` | |
| `gI` | `g I` | `editor::GoToImplementation` | |
| `gt` | `g t` | `editor::GoToTypeDefinition` | |
| `gD` | `g D` | `editor::GoToDeclaration` | |
| `K` | `shift-k` | `editor::Hover` | Also a Zed vim default |

### Code Actions

| Nvim | Zed Binding | Zed Action | Notes |
|------|-------------|------------|-------|
| `<leader>cr` | `space c r` | `editor::Rename` | |
| `<leader>ca` | `space c a` | `editor::ToggleCodeActions` | |
| `<leader>cf` | `space c f` | `editor::Format` | |
| `<leader>cs` | `space c s` | `outline::Toggle` | Replaces Trouble lsp_document_symbols |
| `<leader>co` | `space c o` | `outline::Toggle` | Replaces Aerial float; same as cs in Zed |

**Gaps:** No float vs pinned outline distinction (Aerial). `<leader>cO` not mapped.

### Diagnostics

| Nvim | Zed Binding | Zed Action | Notes |
|------|-------------|------------|-------|
| `]d` / `[d` | `] d` / `[ d` | `editor::GoTo(Prev)Diagnostic` | |
| `]e` / `[e` | `] e` / `[ e` | Same as `]d`/`[d` | No severity filter in Zed |
| `]w` / `[w` | `] w` / `[ w` | Same as `]d`/`[d` | No severity filter in Zed |
| `<leader>dd` | `space d d` | `diagnostics::Deploy` | Replaces Trouble diagnostics |

**Gaps:**
- No severity-filtered navigation (`[e`/`]e` for errors only). All map to the same action.
- `<leader>dt` (Trouble todo) has no equivalent.
- `<leader>ds`/`<leader>dh` (enable/disable diagnostics) not available.
- **Known bug** ([zed#40394](https://github.com/zed-industries/zed/issues/40394)): `GoToDiagnostic` skips `is_unnecessary` diagnostics (e.g. Rust unused-variable warnings) due to a hardcoded filter. Related-info children (info-level) are visited instead. Not configurable. Use diagnostics panel as workaround.

## Cluster 3: Search / Fuzzy Finding (done)

| Nvim | Zed Binding | Zed Action | Notes |
|------|-------------|------------|-------|
| `<leader>sf` | `space s f` | `file_finder::Toggle` | |
| `<leader>sg` | `space s g` | `pane::DeploySearch` | Reuses existing search tab |
| `<leader>s.` | `space s .` | `file_finder::Toggle` | Zed finder shows recents by default |
| `<leader><leader>` | `space space` | `tab_switcher::ToggleAll` | All open files across all panes, sorted by recency |
| `<leader>/` | `space /` | `buffer_search::Deploy` | Search in current buffer |
| `<leader>sr` | `space s r` | `pane::DeploySearch` | Reuses existing search tab with previous query |

**Gaps:**
- `<leader>sw` (grep current word) — no project-search-with-query action yet ([zed PR#47331](https://github.com/zed-industries/zed/pull/47331) pending). Vim `*`/`#` work for in-buffer word search.
- `<leader>s/` (grep in open files only) — no "open files" scope in Zed search.
- `<leader>sh` (help tags), `<leader>sk` (keymaps), `<leader>ss` (select picker), `<leader>sn` (nvim config files) — Telescope-specific, no equivalents.

## Cluster 4: Buffer / Tab Management (planned)

| Nvim | Zed Binding | Zed Action | Notes |
|------|-------------|------------|-------|
| `<leader>bd` | `space b d` | `pane::CloseActiveItem` | |
| `<leader>by` | `space b y` | `editor::CopyPath` | |
| `<leader>bo` | `space b o` | ? | Open with OS — may need SendKeystrokes |
| `H` / `L` | `shift-h` / `shift-l` | `pane::ActivatePrev/NextItem` | Buffer cycling |

## Cluster 5: File Explorer, Git, Comments (planned)

| Nvim | Zed Binding | Zed Action | Notes |
|------|-------------|------------|-------|
| `<leader>e` | `space e` | `project_panel::ToggleFocus` | |
| `<C-n>` | `ctrl-n` | `project_panel::RevealInProjectPanel` | Locate current file |
| `<leader>gb` | `space g b` | `editor::ToggleGitBlame` | |
| `<leader>gg` | `space g g` | ? | LazyGit — open terminal + command? |
| `<leader>/` | `space /` | `editor::ToggleComments` | Normal + visual mode |

## Cluster 6: Terminal, Line Moving (planned)

| Nvim | Zed Binding | Zed Action | Notes |
|------|-------------|------------|-------|
| `<C-,>` | `ctrl-,` | `workspace::ToggleBottomDock` | |
| `<leader>tf` | `space t f` | `workspace::NewCenterTerminal` | Float terminal |
| `<C-S-j/k>` | `ctrl-shift-j/k` | `editor::MoveLineDown/Up` | |

## Not Mapped (no Zed equivalent)

- **REPL** (`<leader>r*`) — no integrated REPL
- **Xcodebuild** (`<leader>x*`) — platform-specific nvim plugin
- **SuperCollider** (`<leader>mS*`) — niche
- **Hex editor** (`<leader>hx`)
- **JQ/FQ playground** (`<leader>jq`, `<leader>fq`)
- **CSV view** — no equivalent
- **Image preview** (`<leader>i*`)
- **Neotest details** — Zed's test runner is more basic
- **Window equalize** (`<leader>=*`)
- **Copilot suggestion cycling** (`<C-=>`/`<C-->`) — Zed handles inline completions differently
