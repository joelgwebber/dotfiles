require('colors').apply('j15r-dark', {
  -- Editor chrome (backgrounds, borders, UI elements)
  editor = {
    bg_primary = '#0f0f0f', -- Main editor background (slightly brighter)
    bg_secondary = '#2a2a2a', -- Elevated elements (popups, floats)
    bg_tertiary = '#3c3c3c', -- Further elevated (selections)
    bg_highlight = '#2f2f2f', -- Highlighted elements
    bg_accent = '#3c3c3c', -- Special backgrounds (cursor line)
    bg_gutter = '#0f0f0f', -- Gutter/sign column background
    border = '#8a8a8a', -- All borders (brighter)
    border_accent = '#b5b5b5', -- Active/focused borders (brighter)
  },

  -- Text hierarchy
  text = {
    primary = '#d0d0d0', -- Main content text (brighter)
    secondary = '#8a8a8a', -- Comments, less important text (brighter)
    tertiary = '#6a6a6a', -- UI text, line numbers (brighter)
    disabled = '#6a6a6a', -- Disabled/ignored text (brighter)
    emphasis = '#e5e595', -- Emphasized text (brighter yellow)
    strong = '#ffb875', -- Strongest emphasis (brighter orange)
    inverse = '#0f0f0f', -- Text on colored backgrounds
  },

  -- Syntax categories
  syntax = {
    variable = '#d0d0d0', -- Variables, normal identifiers (brighter)
    constant = '#e59570', -- Constants, numbers, booleans (brighter orange)
    string = '#95c095', -- Strings, character literals (brighter green)
    keyword = '#c295c2', -- Keywords, control flow (brighter purple)
    func = '#95c2c2', -- Functions, methods (brighter cyan)
    type = '#95c2e5', -- Types, classes (brighter blue)
    operator = '#c295c2', -- Operators (brighter purple)
    preproc = '#c2c295', -- Preprocessor, macros (brighter tan)
    special = '#70a0a0', -- Special characters, regex (brighter darkcyan)
    namespace = '#c2c295', -- Namespaces, modules (brighter tan)
    parameter = '#e59570', -- Parameters, arguments (brighter orange)
    field = '#95c095', -- Object fields, properties (brighter green)
    constructor = '#95c2e5', -- Constructors (brighter blue)
  },

  -- Semantic highlights (LSP, diagnostics, git, etc)
  diagnostic = {
    error = '#e57070', -- Errors (brighter red)
    error_bg = '#4a2525', -- Error backgrounds (slightly brighter)
    error_muted = '#b56565', -- Muted errors (virtual text)

    warning = '#e59570', -- Warnings (brighter orange)
    warning_bg = '#4a3525', -- Warning backgrounds (slightly brighter)
    warning_muted = '#b5826a', -- Muted warnings (virtual text)

    info = '#95c2e5', -- Information (brighter blue)
    info_bg = '#253a4a', -- Info backgrounds (slightly brighter)
    info_muted = '#6a8ab5', -- Muted info (virtual text)

    hint = '#e5c2e5', -- Hints, suggestions (brighter magenta)
    hint_bg = '#3a254a', -- Hint backgrounds (slightly brighter)
    hint_muted = '#a575b5', -- Muted hints (virtual text)

    ok = '#95c095', -- Success, valid (brighter green)
    ok_bg = '#254a25', -- Success backgrounds (slightly brighter)
  },

  -- Version control
  git = {
    added = '#95c095', -- Added lines/text (brighter green)
    added_bg = '#709570', -- Added backgrounds (diff) (brighter)
    modified = '#70a0a0', -- Modified lines/text (brighter cyan)
    modified_bg = '#707070', -- Modified backgrounds (diff) (brighter)
    removed = '#e57070', -- Deleted lines/text (brighter red)
    removed_bg = '#c29570', -- Deleted backgrounds (diff) (brighter)
    conflict = '#c295c2', -- Merge conflicts (brighter purple)
  },

  -- Interactive elements
  ui = {
    selection = '#305030', -- Visual selections (brighter greenish)
    match = '#ff20c2', -- Search matches, matching brackets (brighter magenta)
    search = '#95c095', -- Active search (brighter green)
    search_current = '#c2c295', -- Current search result (brighter tan)
    cursor = '#ffb875', -- Cursor (brighter orange)
    cursor_insert = '#70ff20', -- Insert mode cursor (brighter green)
    cursor_replace = '#e57070', -- Replace mode cursor (brighter red)
    cursor_visual = '#e5c2e5', -- Visual mode cursor (brighter magenta)
  },

  -- Terminal colors (keeping ANSI color semantics)
  -- These need to stay somewhat traditional for terminal apps
  term = {
    black = '#1c1c1c',
    red = '#e57070',
    green = '#95c095',
    yellow = '#c2c295',
    blue = '#7095c2',
    magenta = '#c295c2',
    cyan = '#70a0a0',
    white = '#b5b5b5',
    bright_black = '#8a8a8a',
    bright_red = '#e59570',
    bright_green = '#c2e5c2',
    bright_yellow = '#e5e595',
    bright_blue = '#95c2e5',
    bright_magenta = '#e5c2e5',
    bright_cyan = '#95c2c2',
    bright_white = '#d0d0d0',
  },

  -- Special
  none = 'NONE',
})

