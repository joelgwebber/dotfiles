local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

local function nmap(lhs, rhs, desc)
  map('n', lhs, rhs, desc)
end

local function vmap(lhs, rhs, desc)
  map('v', lhs, rhs, desc)
end

local function nvmap(lhs, rhs, desc)
  map({ 'n', 'v' }, lhs, rhs, desc)
end

-- Document existing key chains
local which = require 'which-key'

-- Missing/clarified descriptions ------------------------------------------------------------------
which.add {
  { 'n', group = '[n]ext result' },
  { 'N', group = 'Prev result' },
  { 'D', group = '[D]elete to end' },
  { 'Y', group = '[Y]ank to end' },
  { 'C', group = '[C]hange to end' },
  { 'c', group = '[c]hange' },
  { 'd', group = '[d]elete' },
  { 'y', group = '[y]ank' },
  { 'v', group = '[v]isual select' },
  { 'g', group = '[g]oto' },
  { 'z', group = 'show' },
  { '<C-F>', group = '[F]orward page' },
  { '<C-B>', group = '[B]ack page' },
  { '<C-U>', group = '[U]p half-page' },
  { '<C-D>', group = '[D]own half-page' },
  { '<C-I>', group = 'Go [I]n' },
  { '<C-O>', group = 'Go [O]ut' },
  { '<C-Y>', group = 'Scroll Up' },
  { '<C-E>', group = 'Scroll Down' },
  { '<leader>', group = 'Commands' },
}

-- Diagnostic messages -----------------------------------------------------------------------------
local diag_prev = function(severity)
  return function()
    vim.diagnostic.goto_prev { severity = severity }
  end
end
local diag_next = function(severity)
  return function()
    vim.diagnostic.goto_next { severity = severity }
  end
end
local diag_enable = function(enabled)
  return function()
    vim.diagnostic.enable(enabled)
  end
end

which.add {
  { '[', group = 'prev' },
  { ']', group = 'next' },
}
nmap('[d', diag_prev(), 'Previous [d]iagnostic')
nmap(']d', diag_next(), 'Next [d]iagnostic')
nmap('[e', diag_prev 'E', 'Previous [e]rror')
nmap(']e', diag_next 'E', 'Next [e]rror')
nmap('[w', diag_prev 'W', 'Previous [w]arning')
nmap(']w', diag_next 'W', 'Next [w]arning')

which.add {
  { '<leader>d', group = '[d]iagnostics' },
}
nmap('<leader>dd', '<cmd>Trouble diagnostics<cr>', '[d]iagnostic [d]isplay')
nmap('<leader>dt', '<cmd>Trouble todo<cr>', '[d]iagnostic [t]odo')
nmap('<leader>ds', diag_enable(true), '[d]iagnostic [s]how')
nmap('<leader>dh', diag_enable(false), '[d]iagnostic [h]ide')

-- Window controls ---------------------------------------------------------------------------------
which.add {
  { '<leader>w', group = '[w]indow' },
}
nmap('<leader>wd', '<cmd>q<cr>', '[w]indow [d]elete')
nmap('<leader>ws', '<cmd>split<cr>', '[w]indow [s]plit')
nmap('<leader>wv', '<cmd>vsplit<cr>', '[w]indow [v]ertical-split')

-- <C-hjkl> window navigation
nmap('<C-h>', '<C-w><C-h>', 'focus left window')
nmap('<C-l>', '<C-w><C-l>', 'focus right window')
nmap('<C-j>', '<C-w><C-j>', 'focus lower window')
nmap('<C-k>', '<C-w><C-k>', 'focus upper window')

-- <C-M-hjkl/ldur> window resizing
nmap('<C-Left>', '4<C-w><lt>', 'Decrease window hsize')
nmap('<C-Right>', '4<C-w>>', 'Increase window vsize')
nmap('<C-Down>', '2<C-w>-', 'Decrease window hsize')
nmap('<C-Up>', '2<C-w>+', 'Increase window vsize')

-- Buffer controls ---------------------------------------------------------------------------------
which.add {
  { '<leader>b', group = '[b]uffer' },
}
nmap('<leader>bd', '<cmd>bdelete<cr>', '[b]uffer [d]elete')
nmap('<leader>bD', '<cmd>bdelete!<cr>', '[b]uffer [D]elete!')
nmap('<leader>by', '<cmd>let @+=expand("%:p")<cr>', '[b]uffer [y]ank path')

-- Code controls -----------------------------------------------------------------------------------
--
-- Both Telescope and Trouble support many of these features (find references, etc).
-- I find Trouble's splitters to be better for navigating code, and prefer Telescope's
-- popup for quick searches (files, buffers, etc).

which.add {
  { '<leader>c', group = '[c]ode' },
}

-- All the symbols in your current document.
nmap('<leader>cs', '<cmd>Trouble lsp_document_symbols<cr>', '[c]ode [s]ymbols')

-- Rename the variable under your cursor.
--  Most Language Servers support renaming across files, etc.
nmap('<leader>cr', vim.lsp.buf.rename, '[c]ode [r]ename')

-- Execute a code action, usually your cursor needs to be on top of an error
-- or a suggestion from your LSP for this to activate.
nmap('<leader>ca', vim.lsp.buf.code_action, '[c]ode [a]ction')

nmap('<leader>cf', function()
  require('conform').format { async = true, lsp_fallback = true }
end, '[c]ode [f]ormat')

-- Opens a popup that displays documentation about the word under your cursor
nmap('K', vim.lsp.buf.hover, 'Hover Documentation')

-- Outline
-- TODO: Make a cleaner abstraction for close/reopen Trouble windows.
nmap('<leader>co', '<cmd>Trouble symbols close<cr>' .. '<cmd>Trouble symbols focus win.relative=win win.position=right<cr>', '[c]ode [o]utline')

-- Jump to the definition of the word under your cursor.
nmap('gd', '<cmd>Trouble lsp_definitions close<cr>' .. '<cmd>Trouble lsp_definitions focus win.relative=win win.position=bottom<cr>', '[g]oto [d]efinition')

-- Find references for the word under your cursor.
-- Disable auto-refresh for references, as it gets in the way of navigation.
nmap(
  'gr',
  '<cmd>Trouble lsp_references close<cr>' .. '<cmd>Trouble lsp_references focus auto_refresh=false win.relative=win win.position=bottom<cr>',
  '[g]oto [r]eferences'
)

-- Jump to the implementation of the word under your cursor.
--  Useful when your language has ways of declaring types without an actual implementation.
nmap(
  'gI',
  '<cmd>Trouble lsp_implementations close<cr>' .. '<cmd>Trouble lsp_implementations focus win.relative=win win.position=bottom<cr>]]',
  '[g]oto [I]mplementation'
)

-- Jump to the type of the word under your cursor.
--  Useful when you're not sure what type a variable is and you want to see
--  the definition of its *type*, not where it was *defined*.
nmap('gt', '<cmd>Trouble lsp_type_definitions close<cr>' .. '<cmd>Trouble lsp_type_definitions focus win.relative=win win.position=bottom<cr>', '[g]oto [t]ype')

-- This is Goto Declaration (not definition).
--  For example, in C this would take you to the header.
nmap('gD', vim.lsp.buf.declaration, '[g]oto [D]eclaration')

-- Search ------------------------------------------------------------------------------------------
which.add {
  { '<leader>s', group = '[s]earch' },
}

local telescope = require 'telescope.builtin'
nmap('<leader>sh', telescope.help_tags, '[s]earch [h]elp')
nmap('<leader>sk', telescope.keymaps, '[s]earch [k]eymaps')
nmap('<leader>sf', telescope.find_files, '[s]earch [f]iles')
nmap('<leader>ss', telescope.builtin, '[s]earch [s]elect Telescope')
nmap('<leader>sw', telescope.grep_string, '[s]earch current [w]ord')
-- nmap('<leader>sg', telescope.live_grep, '[s]earch by [g]rep')
nmap('<leader>sg', '<cmd>lua require("telescope").extensions.live_grep_args.live_grep_args()<cr>', '[s]earch by [g]rep')
nmap('<leader>sr', telescope.resume, '[s]earch [r]esume last')
nmap('<leader>s.', telescope.oldfiles, '[s]earch recent files')
nmap('<leader><leader>', telescope.buffers, 'Find existing buffers')

nmap('<leader>/', function()
  -- You can pass additional configuration to Telescope to change the theme, layout, etc.
  telescope.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, 'Fuzzy [/] search in buffer')

-- It's also possible to pass additional configuration options.
--  See `:help telescope.builtin.live_grep()` for information about particular keys
nmap('<leader>s/', function()
  telescope.live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end, '[s]earch [/] in Open Files')

-- Shortcut for searching your Neovim configuration files
nmap('<leader>sn', function()
  telescope.find_files { cwd = vim.fn.stdpath 'config' }
end, '[s]earch [n]eovim files')

-- Dial --------------------------------------------------------------------------------------------
local dial = require 'dial.map'
nmap('<M-[>', function()
  dial.manipulate('decrement', 'normal')
end, 'Decrement value')
nmap('<M-]>', function()
  dial.manipulate('increment', 'normal')
end, 'Increment value')

-- Flash -------------------------------------------------------------------------------------------
map({ 'n', 'x', 'o' }, 's', function()
  require('flash').jump()
end, 'Flash')
map({ 'n', 'x', 'o' }, 'S', function()
  require('flash').treesitter()
end, 'Flash Treesitter')
map({ 'o', 'x' }, 'R', function()
  require('flash').treesitter_search()
end, 'Treesitter search')

-- Obsidian ----------------------------------------------------------------------------------------
which.add {
  { '<leader>o', group = '[o]bsidian' },
}
nmap('<leader>ow', '<cmd>ObsidianWorkspace<cr>', '[o]bsidian [w]orkspace')
nmap('<leader>oo', '<cmd>ObsidianQuickSwitch<cr>', '[o]bsidian [o]pen')
nmap('<leader>ot', '<cmd>ObsidianToday<cr>', '[o]bsidian [t]oday')
nmap('<leader>os', '<cmd>ObsidianSearch<cr>', '[o]bsidian [s]earch')
nmap('<leader>on', '<cmd>ObsidianNew<cr>', '[o]bsidian [n]ew')

-- Git ---------------------------------------------------------------------------------------------
which.add {
  { '<leader>g', group = '[g]it' },
}
nmap('<leader>gg', '<cmd>LazyGit<cr>', '[g]it Lazy[g]it')
nmap('<leader>gb', '<cmd>GitBlameToggle<cr>', '[g]it [b]lame')

-- Tree --------------------------------------------------------------------------------------------
nmap('<leader>e', '<cmd>e .<cr>', 'File [E]xplorer')
nmap('<C-n>', '<cmd>e %:h<cr>', 'Locate file (popup)')

-- REPL --------------------------------------------------------------------------------------------
which.add {
  { '<leader>r', group = '[r]epl' },
}
nmap('<Leader>rr', '<cmd>REPLStart<cr>', '[r]epl open')
nmap('<Leader>rf', '<cmd>REPLFocus<cr>', '[r]epl [f]ocus')
nmap('<Leader>rs', '<cmd>REPLSendOperator<cr>', '[r]epl [s]end')
nmap('<Leader>rl', '<cmd>REPLSendLine<cr>', '[r]epl send [l]ine')
vmap('<Leader>r', '<cmd>REPLSendVisual<cr>', '[r]epl send')

-- Testing -----------------------------------------------------------------------------------------
which.add {
  { '<leader>t', group = '[t]est' },
}
nmap('<Leader>tt', '<cmd>Neotest summary<cr>', '[t]est show [t]ests')
nmap('<Leader>tr', '<cmd>Neotest run<cr>', '[t]est [r]un')
nmap('<Leader>to', '<cmd>Neotest output-panel<cr>', '[t]est [o]utput')

-- Noice -------------------------------------------------------------------------------------------
-- TODO: Seems to be causing weird errors, and hangs on exit, so I diabled it.
-- which.add {
--   { '<leader>n', group = '[n]oice' },
-- }
-- local noice = require 'noice'
-- nmap('<leader>nl', function()
--   noice.cmd 'last'
-- end, 'Noice Last Message')
-- nmap('<leader>nh', function()
--   noice.cmd 'history'
-- end, 'Noice History')
-- nmap('<leader>na', function()
--   noice.cmd 'all'
-- end, 'Noice All')
-- nmap('<leader>nd', function()
--   noice.cmd 'dismiss'
-- end, 'Dismiss All')

-- Terminal ----------------------------------------------------------------------------------------

-- Clear scrollback hack for the terminal.
map('t', '<C-M-l>', '<cmd>lua ClearScrollback()<cr><C-l>')

function ClearScrollback()
  local sb = vim.bo.scrollback
  vim.bo.scrollback = 1
  vim.bo.scrollback = sb
end

-- SuperCollider -----------------------------------------------------------------------------------
which.add {
  { '<leader>m', group = '[m]usic' },
}
local sc = require 'scnvim'
nmap('<leader>ms', sc.start, '[s]tart')
nmap('<leader>mp', sc.stop, 'sto[p]')
nmap('<leader>mk', sc.recompile, 're[k]ompile')
nmap('<leader>mg', function()
  vim.cmd [[ SCNvimGenerateAssets ]]
end, '[g]enerate')
nmap('<leader>mh', '<cmd>SCNvimHelp Home<cr>', '[h]elp')

-- Aider ------------------------------------------------------------------------------------------
which.add {
  { '<leader>a', group = '[a]ider' },
}
local aider = require 'aider'
nvmap('<leader>aa', function()
  aider.AiderOpen '--dark-mode --pretty --vim --stream --no-auto-commits --subtree-only'
end, '[a]ider [a]sk')

-- Other fixes -------------------------------------------------------------------------------------

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
nmap('<Esc>', '<cmd>nohlsearch<CR>')

-- Make ^E and ^Y a bit less surgical.
-- TODO: Do these in lua. Needs to be non-recursive.
vim.cmd 'noremap ^E 5^E'
vim.cmd 'noremap ^Y 5^Y'
