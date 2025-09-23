require('colors').apply('j15r-dark', {
  -- Editor chrome (backgrounds, borders, UI elements)
  editor = {
    bg_primary = '#080808', -- Main editor background (very dark)
    bg_secondary = '#202020', -- Elevated elements (popups, floats)
    bg_tertiary = '#303030', -- Further elevated (selections)
    bg_highlight = '#262626', -- Highlighted elements
    bg_accent = '#303030', -- Special backgrounds (cursor line)
    bg_gutter = '#080808', -- Gutter/sign column background
    border = '#767676', -- All borders
    border_accent = '#9e9e9e', -- Active/focused borders
  },

  -- Text hierarchy
  text = {
    primary = '#bcbcbc', -- Main content text
    secondary = '#767676', -- Comments, less important text
    tertiary = '#585858', -- UI text, line numbers
    disabled = '#585858', -- Disabled/ignored text
    emphasis = '#d7d787', -- Emphasized text
    strong = '#ffaf5f', -- Strongest emphasis
    inverse = '#080808', -- Text on colored backgrounds
  },

  -- Syntax categories
  syntax = {
    variable = '#bcbcbc', -- Variables, normal identifiers
    constant = '#d7875f', -- Constants, numbers, booleans
    string = '#87af87', -- Strings, character literals
    keyword = '#af87af', -- Keywords, control flow
    func = '#87afaf', -- Functions, methods (cyan)
    type = '#87afd7', -- Types, classes (light blue)
    operator = '#af87af', -- Operators
    preproc = '#afaf87', -- Preprocessor, macros (tan/yellow)
    special = '#5f8787', -- Special characters, regex (darkcyan)
    namespace = '#afaf87', -- Namespaces, modules
    parameter = '#d7875f', -- Parameters, arguments
    field = '#87af87', -- Object fields, properties
    constructor = '#87afd7', -- Constructors
  },

  -- Semantic highlights (LSP, diagnostics, git, etc)
  diagnostic = {
    error = '#d75f5f', -- Errors
    error_bg = '#3a1f1f', -- Error backgrounds
    error_muted = '#9a5858', -- Muted errors (virtual text)

    warning = '#d7875f', -- Warnings
    warning_bg = '#3a2a1f', -- Warning backgrounds
    warning_muted = '#9a7558', -- Muted warnings (virtual text)

    info = '#87afd7', -- Information
    info_bg = '#1f2a3a', -- Info backgrounds
    info_muted = '#5a7a9a', -- Muted info (virtual text)

    hint = '#d7afd7', -- Hints, suggestions
    hint_bg = '#2a1f3a', -- Hint backgrounds
    hint_muted = '#8a6a9a', -- Muted hints (virtual text)

    ok = '#87af87', -- Success, valid
    ok_bg = '#1f3a1f', -- Success backgrounds
  },

  -- Version control
  git = {
    added = '#87af87', -- Added lines/text
    added_bg = '#5f875f', -- Added backgrounds (diff)
    modified = '#5f8787', -- Modified lines/text
    modified_bg = '#5f5f5f', -- Modified backgrounds (diff)
    removed = '#d75f5f', -- Deleted lines/text
    removed_bg = '#af875f', -- Deleted backgrounds (diff)
    conflict = '#af87af', -- Merge conflicts
  },

  -- Interactive elements
  ui = {
    selection = '#204020', -- Visual selections (greenish)
    match = '#ff00af', -- Search matches, matching brackets (magenta)
    search = '#87af87', -- Active search (green)
    search_current = '#afaf87', -- Current search result (tan)
    cursor = '#ffaf5f', -- Cursor (orange)
    cursor_insert = '#5fff00', -- Insert mode cursor (bright green)
    cursor_replace = '#d75f5f', -- Replace mode cursor
    cursor_visual = '#d7afd7', -- Visual mode cursor
  },

  -- Terminal colors (keeping ANSI color semantics)
  -- These need to stay somewhat traditional for terminal apps
  term = {
    black = '#141414',
    red = '#d75f5f',
    green = '#87af87',
    yellow = '#afaf87',
    blue = '#5f87af',
    magenta = '#af87af',
    cyan = '#5f8787',
    white = '#9e9e9e',
    bright_black = '#767676',
    bright_red = '#d7875f',
    bright_green = '#afd7af',
    bright_yellow = '#d7d787',
    bright_blue = '#87afd7',
    bright_magenta = '#d7afd7',
    bright_cyan = '#87afaf',
    bright_white = '#bcbcbc',
  },

  -- Special
  none = 'NONE',
})

