require('colors').apply('j15r', {
  -- Editor chrome (backgrounds, borders, UI elements)
  editor = {
    bg_primary = '#0d1f38', -- Main editor background
    bg_secondary = '#1a2f4a', -- Elevated elements (popups, floats)
    bg_tertiary = '#2a3f5a', -- Further elevated (selections)
    bg_highlight = '#3a4f6a', -- Highlighted elements
    bg_accent = '#1f3450', -- Special backgrounds (cursor line)
    bg_gutter = '#1a2f4a', -- Gutter/sign column background
    border = '#3a4f6a', -- All borders
    border_accent = '#6691a7', -- Active/focused borders
  },

  -- Text hierarchy
  text = {
    primary = '#d4d4d4', -- Main content text
    secondary = '#8a9aa7', -- Comments, less important text
    tertiary = '#8691a7', -- UI text, line numbers
    disabled = '#6691a7', -- Disabled/ignored text
    emphasis = '#e0e0e0', -- Emphasized text
    strong = '#f0f0f0', -- Strongest emphasis
    inverse = '#0d1f38', -- Text on colored backgrounds
  },

  -- Syntax categories
  syntax = {
    variable = '#d4d4d4', -- Variables, normal identifiers
    constant = '#ffc4ff', -- Constants, numbers, booleans
    string = '#7abd70', -- Strings, character literals
    keyword = '#ff79c6', -- Keywords, control flow
    func = '#5ab0d0', -- Functions, methods
    type = '#8be9fd', -- Types, classes
    operator = '#ff79c6', -- Operators
    preproc = '#f1fa8c', -- Preprocessor, macros
    special = '#8be9fd', -- Special characters, regex
    namespace = '#f1fa8c', -- Namespaces, modules
    parameter = '#ffb86c', -- Parameters, arguments
    field = '#7abd70', -- Object fields, properties
    constructor = '#8be9fd', -- Constructors
  },

  -- Semantic highlights (LSP, diagnostics, git, etc)
  diagnostic = {
    error = '#ff4444', -- Errors
    error_bg = '#3a1f1f', -- Error backgrounds
    error_muted = '#aa5868', -- Muted errors (virtual text)

    warning = '#ffb86c', -- Warnings
    warning_bg = '#3a2f1f', -- Warning backgrounds
    warning_muted = '#9a8558', -- Muted warnings (virtual text)

    info = '#8be9fd', -- Information
    info_bg = '#1f2f3a', -- Info backgrounds
    info_muted = '#588a9a', -- Muted info (virtual text)

    hint = '#ffc4ff', -- Hints, suggestions
    hint_bg = '#2f1f3a', -- Hint backgrounds
    hint_muted = '#8a68a0', -- Muted hints (virtual text)

    ok = '#7abd70', -- Success, valid
    ok_bg = '#1f3a1f', -- Success backgrounds
  },

  -- Version control
  git = {
    added = '#7abd70', -- Added lines/text
    added_bg = '#1f3a1f', -- Added backgrounds
    modified = '#ffb86c', -- Modified lines/text
    modified_bg = '#3a2f1f', -- Modified backgrounds
    removed = '#ff4444', -- Deleted lines/text
    removed_bg = '#3a1f1f', -- Deleted backgrounds
    conflict = '#ff79c6', -- Merge conflicts
  },

  -- Interactive elements
  ui = {
    selection = '#44475a', -- Visual selections
    match = '#3a4f6a', -- Search matches, matching brackets
    search = '#f1fa8c', -- Active search
    search_current = '#ffb86c', -- Current search result
    cursor = '#d4d4d4', -- Cursor
    cursor_insert = '#7abd70', -- Insert mode cursor
    cursor_replace = '#ff4444', -- Replace mode cursor
    cursor_visual = '#ffc4ff', -- Visual mode cursor
  },

  -- Terminal colors (keeping ANSI color semantics)
  -- These need to stay somewhat traditional for terminal apps
  term = {
    black = '#0d1f38',
    red = '#ff4444',
    green = '#7abd70',
    yellow = '#f1fa8c',
    blue = '#3a7a9a', -- Muted for selections
    magenta = '#ff79c6',
    cyan = '#8be9fd',
    white = '#d4d4d4',
    bright_black = '#8a9aa7',
    bright_red = '#ff4444',
    bright_green = '#7abd70',
    bright_yellow = '#f1fa8c',
    bright_blue = '#4a8aaa', -- Muted for selections
    bright_magenta = '#ffc4ff',
    bright_cyan = '#8be9fd',
    bright_white = '#f0f0f0',
  },

  -- Special
  none = 'NONE',
})
