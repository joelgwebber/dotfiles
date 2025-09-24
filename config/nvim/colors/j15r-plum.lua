require('colors').apply('j15r-plum', {
  -- Editor chrome (backgrounds, borders, UI elements)
  editor = {
    bg_primary = '#2a2030', -- Muted purple-black background
    bg_secondary = '#3a3040', -- Elevated elements (lighter purple)
    bg_tertiary = '#4a4050', -- Further elevated (selections)
    bg_highlight = '#5a5060', -- Highlighted elements
    bg_accent = '#353045', -- Special backgrounds (cursor line)
    bg_gutter = '#3a3040', -- Gutter/sign column background
    border = '#828282', -- All borders (gray)
    border_accent = '#91989F', -- Active/focused borders (silver)
  },

  -- Text hierarchy
  text = {
    primary = '#F7F1D5', -- Main content text (cream/beige)
    secondary = '#91989F', -- Comments, less important text (silver)
    tertiary = '#828282', -- UI text, line numbers (gray)
    disabled = '#6a6a6a', -- Disabled/ignored text
    emphasis = '#D4A76A', -- Emphasized text (muted gold)
    strong = '#F596AA', -- Strongest emphasis (pink)
    inverse = '#2a2030', -- Text on colored backgrounds
  },

  -- Syntax categories
  syntax = {
    variable = '#F7F1D5', -- Variables, normal identifiers (cream)
    constant = '#F596AA', -- Constants, numbers, booleans (pink/peach)
    string = '#7ac9c9', -- Strings, character literals (soft cyan)
    keyword = '#a8b8e8', -- Keywords, control flow (pale light blue)
    func = '#86C166', -- Functions, methods (green)
    type = '#D4A76A', -- Types, classes (muted gold)
    operator = '#a8b8e8', -- Operators (pale light blue)
    preproc = '#91989F', -- Preprocessor, macros (silver)
    special = '#D4A76A', -- Special characters, regex (muted gold)
    namespace = '#8B81C3', -- Namespaces, modules (purple/wisteria)
    parameter = '#F596AA', -- Parameters, arguments (pink)
    field = '#8B81C3', -- Object fields, properties (purple)
    constructor = '#D4A76A', -- Constructors (muted gold)
  },

  -- Semantic highlights (LSP, diagnostics, git, etc)
  diagnostic = {
    error = '#D05A6E', -- Errors (crimson/pink-red)
    error_bg = '#3a1f2a', -- Error backgrounds
    error_muted = '#9a5868', -- Muted errors (virtual text)

    warning = '#D4A76A', -- Warnings (muted gold)
    warning_bg = '#3a3a1f', -- Warning backgrounds
    warning_muted = '#9a8558', -- Muted warnings (virtual text)

    info = '#8B81C3', -- Information (purple)
    info_bg = '#2a1f3a', -- Info backgrounds
    info_muted = '#6a5a8a', -- Muted info (virtual text)

    hint = '#F596AA', -- Hints, suggestions (pink)
    hint_bg = '#3a1f2a', -- Hint backgrounds
    hint_muted = '#9a6878', -- Muted hints (virtual text)

    ok = '#86C166', -- Success, valid (green)
    ok_bg = '#1f3a1f', -- Success backgrounds
  },

  -- Version control
  git = {
    added = '#86C166', -- Added lines/text (green)
    added_bg = '#2a3a2a', -- Added backgrounds
    modified = '#D4A76A', -- Modified lines/text (muted gold)
    modified_bg = '#3a3a2a', -- Modified backgrounds
    removed = '#D05A6E', -- Deleted lines/text (crimson)
    removed_bg = '#3a2a2a', -- Deleted backgrounds
    conflict = '#F596AA', -- Merge conflicts (pink)
  },

  -- Interactive elements
  ui = {
    selection = '#4a3a55', -- Visual selections (purple tint)
    match = '#D4A76A', -- Search matches, matching brackets (muted gold)
    search = '#D4A76A', -- Active search (muted gold)
    search_current = '#F596AA', -- Current search result (pink)
    cursor = '#D4A76A', -- Cursor (muted gold)
    cursor_insert = '#86C166', -- Insert mode cursor (green)
    cursor_replace = '#D05A6E', -- Replace mode cursor (crimson)
    cursor_visual = '#8B81C3', -- Visual mode cursor (purple)
  },

  -- Terminal colors (keeping ANSI color semantics)
  -- Using japanesque palette adapted for terminal
  term = {
    black = '#3C2F41', -- Original purple-black
    red = '#D05A6E', -- Crimson
    green = '#86C166', -- Green
    yellow = '#D4A76A', -- Muted gold
    blue = '#5a4a65', -- Muted purple for selections (less contrast)
    magenta = '#F596AA', -- Pink
    cyan = '#7ac9c9', -- Soft cyan
    white = '#F7F1D5', -- Cream
    bright_black = '#828282', -- Gray
    bright_red = '#D05A6E', -- Crimson (same)
    bright_green = '#86C166', -- Green (same)
    bright_yellow = '#D4A76A', -- Muted gold
    bright_blue = '#6a5a75', -- Slightly brighter muted purple
    bright_magenta = '#F596AA', -- Pink (same)
    bright_cyan = '#91989F', -- Silver
    bright_white = '#F7F1D5', -- Cream (same)
  },

  -- Special
  none = 'NONE',
})

