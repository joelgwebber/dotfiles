require('colors').apply('j15rcyan', {
  -- Editor chrome (backgrounds, borders, UI elements)
  editor = {
    bg_primary = '#0a2a2a', -- Deep cyan-tinted background
    bg_secondary = '#1a3838', -- Elevated elements (popups, floats)
    bg_tertiary = '#2a4848', -- Further elevated (selections)
    bg_highlight = '#3a5858', -- Highlighted elements
    bg_accent = '#1f3d3d', -- Special backgrounds (cursor line)
    bg_gutter = '#1a3838', -- Gutter/sign column background
    border = '#3a5858', -- All borders
    border_accent = '#5a9a9a', -- Active/focused borders
  },

  -- Text hierarchy
  text = {
    primary = '#d0d0d0', -- Main content text
    secondary = '#8a9a9a', -- Comments, less important text
    tertiary = '#788a8a', -- UI text, line numbers
    disabled = '#556868', -- Disabled/ignored text
    emphasis = '#e6e6e6', -- Emphasized text
    strong = '#fcfcfc', -- Strongest emphasis
    inverse = '#0a2a2a', -- Text on colored backgrounds
  },

  -- Syntax categories
  syntax = {
    variable = '#d0d0d0', -- Variables, normal identifiers
    constant = '#ffb9e5', -- Constants, numbers, booleans (magenta-pink)
    string = '#82e3ba', -- Strings, character literals (cyan-green)
    keyword = '#a9d4ff', -- Keywords, control flow (light cyan-blue)
    func = '#5ab0d0', -- Functions, methods (cyan)
    type = '#8be9fd', -- Types, classes (bright cyan)
    operator = '#a9d4ff', -- Operators
    preproc = '#ebcd91', -- Preprocessor, macros (warm yellow-tan)
    special = '#bb6d9b', -- Special characters, regex (purple-pink)
    namespace = '#209870', -- Namespaces, modules (teal-green)
    parameter = '#9f8340', -- Parameters, arguments (warm brown)
    field = '#82e3ba', -- Object fields, properties
    constructor = '#8be9fd', -- Constructors
  },

  -- Semantic highlights (LSP, diagnostics, git, etc)
  diagnostic = {
    error = '#ff6666', -- Errors (coral red)
    error_bg = '#3a1f1f', -- Error backgrounds
    error_muted = '#aa6878', -- Muted errors (virtual text)

    warning = '#ebcd91', -- Warnings (warm tan)
    warning_bg = '#3a2f1f', -- Warning backgrounds
    warning_muted = '#9a8558', -- Muted warnings (virtual text)

    info = '#8be9fd', -- Information (bright cyan)
    info_bg = '#1f3a3a', -- Info backgrounds
    info_muted = '#5a8a8a', -- Muted info (virtual text)

    hint = '#bb6d9b', -- Hints, suggestions (purple-pink)
    hint_bg = '#2a1f2a', -- Hint backgrounds
    hint_muted = '#7a5a7a', -- Muted hints (virtual text)

    ok = '#82e3ba', -- Success, valid (cyan-green)
    ok_bg = '#1f3a2a', -- Success backgrounds
  },

  -- Version control
  git = {
    added = '#82e3ba', -- Added lines/text (cyan-green)
    added_bg = '#1f3a2a', -- Added backgrounds
    modified = '#ebcd91', -- Modified lines/text (warm tan)
    modified_bg = '#3a2f1f', -- Modified backgrounds
    removed = '#ff6666', -- Deleted lines/text (coral red)
    removed_bg = '#3a1f1f', -- Deleted backgrounds
    conflict = '#bb6d9b', -- Merge conflicts (purple-pink)
  },

  -- Interactive elements
  ui = {
    selection = '#2a4848', -- Visual selections
    match = '#3a5858', -- Search matches, matching brackets
    search = '#ebcd91', -- Active search (warm tan)
    search_current = '#ffb86c', -- Current search result
    cursor = '#d0d0d0', -- Cursor
    cursor_insert = '#82e3ba', -- Insert mode cursor (cyan-green)
    cursor_replace = '#ff6666', -- Replace mode cursor (coral red)
    cursor_visual = '#bb6d9b', -- Visual mode cursor (purple-pink)
  },

  -- Terminal colors (keeping ANSI color semantics)
  -- These need to stay somewhat traditional for terminal apps
  term = {
    black = '#0a2a2a',
    red = '#ff6666',
    green = '#82e3ba',
    yellow = '#ebcd91',
    blue = '#7a9fd9', -- Readable blue for URLs
    magenta = '#bb6d9b',
    cyan = '#8be9fd',
    white = '#d0d0d0',
    bright_black = '#788a8a',
    bright_red = '#ff8888',
    bright_green = '#a0f0d0',
    bright_yellow = '#f0d8a8',
    bright_blue = '#9ab4e9', -- Brighter blue for URLs
    bright_magenta = '#ffb9e5',
    bright_cyan = '#a0f0ff',
    bright_white = '#fcfcfc',
  },

  -- Special
  none = 'NONE',
})

