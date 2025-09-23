-- Shared color scheme framework
-- This defines the structure and highlight mappings for all color schemes

local M = {}

-- Helper function to set highlights
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Apply a color palette to create a complete color scheme
function M.apply(name, colors)
  -- Reset highlights
  if vim.g.colors_name then
    vim.cmd 'highlight clear'
  end
  if vim.fn.exists 'syntax_on' then
    vim.cmd 'syntax reset'
  end

  vim.g.colors_name = name or 'custom'
  vim.o.termguicolors = true

  -- Terminal colors
  vim.g.terminal_color_0 = colors.term.black
  vim.g.terminal_color_1 = colors.term.red
  vim.g.terminal_color_2 = colors.term.green
  vim.g.terminal_color_3 = colors.term.yellow
  vim.g.terminal_color_4 = colors.term.blue
  vim.g.terminal_color_5 = colors.term.magenta
  vim.g.terminal_color_6 = colors.term.cyan
  vim.g.terminal_color_7 = colors.term.white
  vim.g.terminal_color_8 = colors.term.bright_black
  vim.g.terminal_color_9 = colors.term.bright_red
  vim.g.terminal_color_10 = colors.term.bright_green
  vim.g.terminal_color_11 = colors.term.bright_yellow
  vim.g.terminal_color_12 = colors.term.bright_blue
  vim.g.terminal_color_13 = colors.term.bright_magenta
  vim.g.terminal_color_14 = colors.term.bright_cyan
  vim.g.terminal_color_15 = colors.term.bright_white

  -- Editor highlights
  hi('Normal', { fg = colors.text.primary, bg = colors.editor.bg_primary })
  hi('NormalFloat', { fg = colors.text.primary, bg = colors.editor.bg_secondary })
  hi('NormalNC', { fg = colors.text.primary, bg = colors.editor.bg_primary })
  -- FloatBorder: Solid border effect using matching bg colors
  -- When using 'single' borders: fg draws the line, bg is the padding
  -- For solid appearance: set bg to match the float window bg (bg_secondary)
  -- and fg to a contrasting color for the border line
  hi('FloatBorder', { fg = colors.editor.bg_highlight, bg = colors.editor.bg_secondary })
  hi('FloatTitle', { fg = colors.text.emphasis, bg = colors.editor.bg_secondary })

  hi('Cursor', { fg = colors.editor.bg_primary, bg = colors.ui.cursor })
  hi('CursorLine', { bg = colors.editor.bg_accent })
  hi('CursorLineNr', { fg = colors.text.emphasis, bg = colors.editor.bg_accent })
  hi('CursorColumn', { bg = colors.editor.bg_accent })

  hi('LineNr', { fg = colors.text.tertiary, bg = colors.editor.bg_gutter })
  hi('SignColumn', { fg = colors.text.tertiary, bg = colors.editor.bg_gutter })
  hi('FoldColumn', { fg = colors.syntax.special, bg = colors.editor.bg_gutter })
  hi('Folded', { fg = colors.text.secondary, bg = colors.editor.bg_tertiary })

  -- Use solid color for window separators instead of line characters
  hi('VertSplit', { fg = colors.editor.bg_tertiary, bg = colors.editor.bg_tertiary })
  hi('WinSeparator', { fg = colors.editor.bg_tertiary, bg = colors.editor.bg_tertiary })
  hi('StatusLine', { fg = colors.text.primary, bg = colors.editor.bg_tertiary })
  hi('StatusLineNC', { fg = colors.text.secondary, bg = colors.editor.bg_secondary })
  hi('TabLine', { fg = colors.text.secondary, bg = colors.editor.bg_secondary })
  hi('TabLineFill', { fg = colors.text.secondary, bg = colors.editor.bg_secondary })
  hi('TabLineSel', { fg = colors.diagnostic.ok, bg = colors.editor.bg_secondary })

  hi('Visual', { bg = colors.ui.selection })
  hi('VisualNOS', { bg = colors.ui.selection })
  hi('Search', { fg = colors.editor.bg_primary, bg = colors.ui.search })
  hi('IncSearch', { fg = colors.editor.bg_primary, bg = colors.ui.search_current })
  hi('CurSearch', { fg = colors.editor.bg_primary, bg = colors.ui.search_current })

  hi('ColorColumn', { bg = colors.editor.bg_secondary })
  hi('Conceal', { fg = colors.syntax.func })
  hi('Directory', { fg = colors.syntax.func })
  hi('EndOfBuffer', { fg = colors.text.secondary })
  hi('ErrorMsg', { fg = colors.diagnostic.error, bg = colors.editor.bg_primary })
  hi('WarningMsg', { fg = colors.diagnostic.warning })
  hi('ModeMsg', { fg = colors.diagnostic.ok })
  hi('MoreMsg', { fg = colors.diagnostic.ok })
  hi('Question', { fg = colors.syntax.func })

  hi('MatchParen', { bg = colors.ui.match })
  hi('NonText', { fg = colors.text.secondary })
  hi('SpecialKey', { fg = colors.text.secondary })
  hi('Whitespace', { fg = colors.text.secondary })
  hi('WildMenu', { fg = colors.diagnostic.error, bg = colors.ui.search })

  hi('Pmenu', { fg = colors.text.primary, bg = colors.editor.bg_secondary })
  hi('PmenuSel', { fg = colors.editor.bg_primary, bg = colors.syntax.func })
  hi('PmenuSbar', { bg = colors.editor.bg_tertiary })
  hi('PmenuThumb', { bg = colors.text.primary })

  -- Syntax highlights
  hi('Comment', { fg = colors.text.secondary })
  hi('Constant', { fg = colors.syntax.constant })
  hi('String', { fg = colors.syntax.string })
  hi('Character', { fg = colors.syntax.string })
  hi('Number', { fg = colors.syntax.constant })
  hi('Boolean', { fg = colors.syntax.constant })
  hi('Float', { fg = colors.syntax.constant })

  hi('Identifier', { fg = colors.diagnostic.error }) -- Often used for special identifiers
  hi('Function', { fg = colors.syntax.func })

  hi('Statement', { fg = colors.syntax.keyword })
  hi('Conditional', { fg = colors.syntax.keyword })
  hi('Repeat', { fg = colors.syntax.keyword })
  hi('Label', { fg = colors.syntax.keyword })
  hi('Operator', { fg = colors.syntax.operator })
  hi('Keyword', { fg = colors.syntax.keyword })
  hi('Exception', { fg = colors.syntax.keyword })

  hi('PreProc', { fg = colors.syntax.preproc })
  hi('Include', { fg = colors.syntax.keyword })
  hi('Define', { fg = colors.syntax.keyword })
  hi('Macro', { fg = colors.syntax.keyword })
  hi('PreCondit', { fg = colors.syntax.preproc })

  hi('Type', { fg = colors.syntax.type })
  hi('StorageClass', { fg = colors.syntax.type })
  hi('Structure', { fg = colors.syntax.type })
  hi('Typedef', { fg = colors.syntax.type })

  hi('Special', { fg = colors.syntax.special })
  hi('SpecialChar', { fg = colors.syntax.special })
  hi('Tag', { fg = colors.syntax.special })
  hi('Delimiter', { fg = colors.text.primary })
  hi('SpecialComment', { fg = colors.text.secondary })
  hi('Debug', { fg = colors.diagnostic.error })

  hi('Underlined', { fg = colors.syntax.type, underline = true })
  hi('Ignore', { fg = colors.text.disabled })
  hi('Error', { fg = colors.diagnostic.error, bg = colors.editor.bg_primary })
  hi('Todo', { fg = colors.ui.search, bg = colors.editor.bg_primary, bold = true })

  -- Diff highlights
  hi('DiffAdd', { fg = colors.git.added, bg = colors.editor.bg_secondary })
  hi('DiffChange', { fg = colors.git.modified, bg = colors.editor.bg_secondary })
  hi('DiffDelete', { fg = colors.git.removed, bg = colors.editor.bg_secondary })
  hi('DiffText', { fg = colors.syntax.func, bg = colors.editor.bg_secondary })

  -- Spell highlights
  hi('SpellBad', { sp = colors.diagnostic.error, undercurl = true })
  hi('SpellCap', { sp = colors.syntax.func, undercurl = true })
  hi('SpellLocal', { sp = colors.syntax.type, undercurl = true })
  hi('SpellRare', { sp = colors.syntax.constant, undercurl = true })

  -- LSP and Diagnostics
  hi('DiagnosticError', { fg = colors.diagnostic.error_muted, italic = true })
  hi('DiagnosticWarn', { fg = colors.diagnostic.warning_muted, italic = true })
  hi('DiagnosticInfo', { fg = colors.diagnostic.info_muted, italic = true })
  hi('DiagnosticHint', { fg = colors.diagnostic.hint_muted, italic = true })
  hi('DiagnosticUnderlineError', { sp = colors.diagnostic.error_muted, undercurl = true })
  hi('DiagnosticUnderlineWarn', { sp = colors.diagnostic.warning_muted, undercurl = true })
  hi('DiagnosticUnderlineInfo', { sp = colors.diagnostic.info_muted, undercurl = true })
  hi('DiagnosticUnderlineHint', { sp = colors.diagnostic.hint_muted, undercurl = true })

  -- Virtual text for diagnostics
  hi('DiagnosticVirtualTextError', { fg = colors.diagnostic.error_muted, italic = true })
  hi('DiagnosticVirtualTextWarn', { fg = colors.diagnostic.warning_muted, italic = true })
  hi('DiagnosticVirtualTextInfo', { fg = colors.diagnostic.info_muted, italic = true })
  hi('DiagnosticVirtualTextHint', { fg = colors.diagnostic.hint_muted, italic = true })

  hi('LspReferenceText', { bg = colors.editor.bg_tertiary })
  hi('LspReferenceRead', { bg = colors.editor.bg_tertiary })
  hi('LspReferenceWrite', { bg = colors.editor.bg_tertiary })

  -- TreeSitter highlights
  hi('@comment', { link = 'Comment' })
  hi('@constant', { link = 'Constant' })
  hi('@constant.builtin', { link = 'Constant' })
  hi('@constant.macro', { link = 'Define' })
  hi('@string', { link = 'String' })
  hi('@string.escape', { link = 'SpecialChar' })
  hi('@character', { link = 'Character' })
  hi('@number', { link = 'Number' })
  hi('@boolean', { link = 'Boolean' })
  hi('@float', { link = 'Float' })
  hi('@function', { link = 'Function' })
  hi('@function.builtin', { link = 'Function' })
  hi('@function.macro', { link = 'Macro' })
  hi('@parameter', { fg = colors.syntax.parameter })
  hi('@method', { link = 'Function' })
  hi('@field', { fg = colors.syntax.field })
  hi('@property', { fg = colors.syntax.type })
  hi('@constructor', { fg = colors.syntax.constructor })
  hi('@conditional', { link = 'Conditional' })
  hi('@repeat', { link = 'Repeat' })
  hi('@label', { link = 'Label' })
  hi('@operator', { link = 'Operator' })
  hi('@keyword', { link = 'Keyword' })
  hi('@exception', { link = 'Exception' })
  hi('@variable', { fg = colors.syntax.variable })
  hi('@type', { link = 'Type' })
  hi('@type.definition', { link = 'Typedef' })
  hi('@storageclass', { link = 'StorageClass' })
  hi('@namespace', { fg = colors.syntax.namespace })
  hi('@include', { link = 'Include' })
  hi('@preproc', { link = 'PreProc' })
  hi('@debug', { link = 'Debug' })
  hi('@tag', { link = 'Tag' })

  -- Plugin: Telescope
  hi('TelescopeNormal', { fg = colors.text.primary, bg = colors.editor.bg_secondary })
  hi('TelescopeBorder', { fg = colors.editor.bg_highlight, bg = colors.editor.bg_secondary })
  hi('TelescopeSelection', { bg = colors.editor.bg_tertiary })
  hi('TelescopeSelectionCaret', { fg = colors.diagnostic.error })
  hi('TelescopeMatching', { fg = colors.ui.search_current, bold = true })
  hi('TelescopePromptPrefix', { fg = colors.syntax.func })

  -- Plugin: nvim-cmp
  hi('CmpItemAbbrMatch', { fg = colors.syntax.func, bold = true })
  hi('CmpItemAbbrMatchFuzzy', { fg = colors.syntax.func, bold = true })
  hi('CmpItemKind', { fg = colors.syntax.type })
  hi('CmpItemMenu', { fg = colors.text.secondary })

  -- Plugin: GitSigns
  hi('GitSignsAdd', { fg = colors.git.added, bg = colors.editor.bg_gutter })
  hi('GitSignsChange', { fg = colors.git.modified, bg = colors.editor.bg_gutter })
  hi('GitSignsDelete', { fg = colors.git.removed, bg = colors.editor.bg_gutter })

  -- Plugin: which-key
  hi('WhichKey', { fg = colors.syntax.constant })

  -- Plugin: mini.files
  hi('MiniFilesNormal', { fg = colors.text.primary, bg = colors.editor.bg_secondary })
  hi('MiniFilesBorder', { fg = colors.editor.bg_highlight, bg = colors.editor.bg_secondary })
  hi('MiniFilesBorderModified', { fg = colors.diagnostic.warning, bg = colors.editor.bg_secondary })
  hi('MiniFilesTitle', { fg = colors.text.emphasis, bg = colors.editor.bg_secondary })
  hi('MiniFilesTitleFocused', { fg = colors.text.strong, bg = colors.editor.bg_secondary })
  hi('MiniFilesCursorLine', { bg = colors.editor.bg_tertiary })

  -- Plugin: lazygit
  hi('LazyGitFloat', { fg = colors.text.primary, bg = colors.editor.bg_secondary })
  hi('LazyGitBorder', { fg = colors.editor.bg_highlight, bg = colors.editor.bg_secondary })
  hi('WhichKeyGroup', { fg = colors.syntax.func })
  hi('WhichKeyDesc', { fg = colors.syntax.type })
  hi('WhichKeySeparator', { fg = colors.text.secondary })
  hi('WhichKeyFloat', { bg = colors.editor.bg_secondary })

  -- Plugin: Aerial
  hi('AerialLine', { bg = colors.editor.bg_tertiary })
  hi('AerialLineNC', { bg = colors.editor.bg_secondary })
  hi('AerialBorder', { fg = colors.editor.border, bg = colors.editor.bg_primary })
  hi('AerialNormal', { fg = colors.text.primary, bg = colors.editor.bg_secondary })

  -- Plugin: Trouble
  hi('TroubleText', { fg = colors.text.primary })
  hi('TroubleCount', { fg = colors.syntax.keyword, bg = colors.editor.bg_tertiary })
  hi('TroubleNormal', { fg = colors.text.primary, bg = colors.editor.bg_secondary })
  hi('TroubleLocation', { fg = colors.text.tertiary, bg = colors.editor.bg_secondary })
  hi('TroubleIndent', { fg = colors.text.tertiary, bg = colors.editor.bg_secondary })
  hi('TroubleFoldIcon', { fg = colors.text.tertiary, bg = colors.editor.bg_secondary })
  hi('TroubleFile', { fg = colors.text.primary, bg = colors.editor.bg_secondary })
  hi('TroubleSource', { fg = colors.text.tertiary, bg = colors.editor.bg_secondary })
  hi('TroubleCode', { fg = colors.text.secondary, bg = colors.editor.bg_secondary })

  -- Plugin: todo-comments
  hi('TodoBgTODO', { fg = colors.editor.bg_primary, bg = colors.ui.search, bold = true })
  hi('TodoBgNOTE', { fg = colors.editor.bg_primary, bg = colors.syntax.type, bold = true })
  hi('TodoBgWARN', { fg = colors.editor.bg_primary, bg = colors.diagnostic.warning, bold = true })
  hi('TodoBgFIX', { fg = colors.editor.bg_primary, bg = colors.diagnostic.error, bold = true })

  -- Plugin: lazy.nvim
  hi('LazyButton', { bg = colors.editor.bg_tertiary })
  hi('LazyButtonActive', { bg = colors.editor.bg_highlight })
  hi('LazyH1', { fg = colors.syntax.func, bold = true })
  hi('LazySpecial', { fg = colors.syntax.type })
  hi('LazyProgressTodo', { fg = colors.text.secondary })
  hi('LazyProgressDone', { fg = colors.diagnostic.ok })

  -- Plugin: mini.nvim (other mini plugins)
  hi('MiniPickBorder', { fg = colors.editor.border, bg = colors.editor.bg_primary })
  hi('MiniPickNormal', { fg = colors.text.primary, bg = colors.editor.bg_secondary })
end

return M
