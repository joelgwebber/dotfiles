local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

local function nmap(lhs, rhs, desc)
  map('n', lhs, rhs, desc)
end

local function vmap(lhs, rhs, desc)
  map('v', lhs, rhs, desc)
end

-- Document existing key chains
local which = require 'which-key'
which.add {
  ['g'] = { name = '[g]oto', _ = 'which_key_ignore' },
}

-- Missing/clarified descriptions ------------------------------------------------------------------
which.add {
  ['n'] = { name = '[n]ext result', _ = 'which_key_ignore' },
  ['N'] = { name = 'Prev result', _ = 'which_key_ignore' },
  ['D'] = { name = '[D]elete to end', _ = 'which_key_ignore' },
  ['Y'] = { name = '[Y]ank to end', _ = 'which_key_ignore' },
  ['C'] = { name = '[C]hange to end', _ = 'which_key_ignore' },
  ['c'] = { name = '[c]hange', _ = 'which_key_ignore' },
  ['d'] = { name = '[d]elete', _ = 'which_key_ignore' },
  ['y'] = { name = '[y]ank', _ = 'which_key_ignore' },
  ['v'] = { name = '[v]isual select', _ = 'which_key_ignore' },
  ['<C-F>'] = { name = '[F]orward page', _ = 'which_key_ignore' },
  ['<C-B>'] = { name = '[B]ack page', _ = 'which_key_ignore' },
  ['<C-U>'] = { name = '[U]p half-page', _ = 'which_key_ignore' },
  ['<C-D>'] = { name = '[D]own half-page', _ = 'which_key_ignore' },
  ['<C-I>'] = { name = 'Go [I]n', _ = 'which_key_ignore' },
  ['<C-O>'] = { name = 'Go [O]ut', _ = 'which_key_ignore' },
  ['<C-Y>'] = { name = 'Scroll Up', _ = 'which_key_ignore' },
  ['<C-E>'] = { name = 'Scroll Down', _ = 'which_key_ignore' },
  ['<leader>'] = { name = 'Commands', _ = 'which_key_ignore' },
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
  ['['] = { name = 'prev', _ = 'which_key_ignore' },
  [']'] = { name = 'next', _ = 'which_key_ignore' },
}
nmap('[d', diag_prev(), 'Previous [d]iagnostic')
nmap(']d', diag_next(), 'Next [d]iagnostic')
nmap('[e', diag_prev 'E', 'Previous [e]rror')
nmap(']e', diag_next 'E', 'Next [e]rror')
nmap('[w', diag_prev 'W', 'Previous [w]arning')
nmap(']w', diag_next 'W', 'Next [w]arning')

which.add {
  ['<leader>d'] = { name = '[d]iagnostics', _ = 'which_key_ignore' },
}
nmap('<leader>dd', '<cmd>Trouble diagnostics<cr>', '[d]iagnostic [d]isplay')
nmap('<leader>dt', '<cmd>Trouble todo<cr>', '[d]iagnostic [t]odo')
nmap('<leader>ds', diag_enable(true), '[d]iagnostic [s]how')
nmap('<leader>dh', diag_enable(false), '[d]iagnostic [h]ide')

-- Window controls ---------------------------------------------------------------------------------
which.add {
  ['<leader>w'] = { name = '[w]indow', _ = 'which_key_ignore' },
}
nmap('<leader>wd', '<cmd>q<cr>', '[w]indow [d]elete')
nmap('<leader>ws', '<cmd>split<cr>', '[w]indow [s]plit')
nmap('<leader>wv', '<cmd>vsplit<cr>', '[w]indow [v]ertical-split')

-- <C-hjkl> window navigation
nmap('<C-h>', '<C-w><C-h>', 'focus left window')
nmap('<C-l>', '<C-w><C-l>', 'focus right window')
nmap('<C-j>', '<C-w><C-j>', 'focus lower window')
nmap('<C-k>', '<C-w><C-k>', 'focus upper window')

-- <C-S-hjkl/ldur> window resizing
nmap('<C-S-h>', '4<C-w><lt>', 'Decrease window hsize')
nmap('<C-S-l>', '4<C-w>>', 'Increase window hsize')
nmap('<C-S-j>', '2<C-w>-', 'Decrease window vsize')
nmap('<C-S-k>', '2<C-w>+', 'Increase window vsize')
nmap('<C-Left>', '4<C-w><lt>', 'Decrease window hsize')
nmap('<C-Right>', '4<C-w>>', 'Increase window vsize')
nmap('<C-Down>', '2<C-w>-', 'Decrease window hsize')
nmap('<C-Up>', '2<C-w>+', 'Increase window vsize')

-- Buffer controls ---------------------------------------------------------------------------------
which.add {
  ['<leader>b'] = { name = '[b]uffer', _ = 'which_key_ignore' },
}
nmap('<leader>bd', '<cmd>bdelete<cr>', '[b]uffer [d]elete')
nmap('<leader>bD', '<cmd>bdelete!<cr>', '[b]uffer [D]elete!')

-- Code controls -----------------------------------------------------------------------------------
--
-- Both Telescope and Trouble support many of these features (find references, etc).
-- I find Trouble's splitters to be better for navigating code, and prefer Telescope's
-- popup for quick searches (files, buffers, etc).

which.add {
  ['<leader>c'] = { name = '[c]ode', _ = 'which_key_ignore' },
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
nmap('gr', '<cmd>Trouble lsp_references close<cr>' .. '<cmd>Trouble lsp_references focus win.relative=win win.position=bottom<cr>', '[g]oto [r]eferences')

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
  ['<leader>s'] = { name = '[s]earch', _ = 'which_key_ignore' },
}

local telescope = require 'telescope.builtin'
nmap('<leader>sh', telescope.help_tags, '[s]earch [h]elp')
nmap('<leader>sk', telescope.keymaps, '[s]earch [k]eymaps')
nmap('<leader>sf', telescope.find_files, '[s]earch [f]iles')
nmap('<leader>ss', telescope.builtin, '[s]earch [s]elect Telescope')
nmap('<leader>sw', telescope.grep_string, '[s]earch current [w]ord')
nmap('<leader>sg', telescope.live_grep, '[s]earch by [g]rep')
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

-- TODO: This was recommended in the docs, but I don't quite get it.
-- map({ 'o' }, 'r', function()
--   require('flash').remote()
-- end, 'Remote Flash')

-- Obsidian ----------------------------------------------------------------------------------------
which.add {
  ['<leader>o'] = { name = '[o]bsidian', _ = 'which_key_ignore' },
}
nmap('<leader>ow', '<cmd>ObsidianWorkspace<cr>', '[o]bsidian [w]orkspace')
nmap('<leader>oo', '<cmd>ObsidianQuickSwitch<cr>', '[o]bsidian [o]pen')
nmap('<leader>ot', '<cmd>ObsidianToday<cr>', '[o]bsidian [t]oday')
nmap('<leader>os', '<cmd>ObsidianSearch<cr>', '[o]bsidian [s]earch')
nmap('<leader>on', '<cmd>ObsidianNew<cr>', '[o]bsidian [n]ew')

-- Git ---------------------------------------------------------------------------------------------
which.add {
  ['<leader>g'] = { name = '[g]it', _ = 'which_key_ignore' },
}
nmap('<leader>gg', '<cmd>LazyGit<cr>', '[g]it Lazy[g]it')
nmap('<leader>gb', '<cmd>GitBlameToggle<cr>', '[g]it [b]lame')

-- Tree --------------------------------------------------------------------------------------------
nmap('<leader>e', '<cmd>NvimTreeOpen<cr>', 'Tr[e]e')
nmap('<C-n>', function()
  require('nvim-tree.api').tree.open { find_file = true, update_root = true }
end, 'Locate file')

-- REPL --------------------------------------------------------------------------------------------
which.add {
  ['<leader>r'] = { name = '[r]epl', _ = 'which_key_ignore' },
}
nmap('<Leader>rr', '<cmd>REPLStart<cr>', '[r]epl open')
nmap('<Leader>rf', '<cmd>REPLFocus<cr>', '[r]epl [f]ocus')
nmap('<Leader>rs', '<cmd>REPLSendOperator<cr>', '[r]epl [s]end')
nmap('<Leader>rl', '<cmd>REPLSendLine<cr>', '[r]epl send [l]ine')
vmap('<Leader>r', '<cmd>REPLSendVisual<cr>', '[r]epl send')

-- Testing -----------------------------------------------------------------------------------------
which.add {
  ['<leader>t'] = { name = '[t]est', _ = 'which_key_ignore' },
}
nmap('<Leader>tt', '<cmd>Neotest summary<cr>', '[t]est show [t]ests')
nmap('<Leader>tr', '<cmd>Neotest run<cr>', '[t]est [r]un')
nmap('<Leader>to', '<cmd>Neotest output-panel<cr>', '[t]est [o]utput')

-- Noice -------------------------------------------------------------------------------------------
which.add {
  ['<leader>n'] = { name = '[n]oice', _ = 'which_key_ignore' },
}
local noice = require 'noice'
nmap('<leader>nl', function()
  noice.cmd 'last'
end, 'Noice Last Message')
nmap('<leader>nh', function()
  noice.cmd 'history'
end, 'Noice History')
nmap('<leader>na', function()
  noice.cmd 'all'
end, 'Noice All')
nmap('<leader>nd', function()
  noice.cmd 'dismiss'
end, 'Dismiss All')

-- Terminal ----------------------------------------------------------------------------------------

-- Esc/Esc to exit terminal
map('t', '<Esc><Esc>', '<C-\\><C-n>', 'Exit terminal mode')

-- Clear scrollback hack for the terminal.
map('t', '<C-S-l>', '<cmd>lua ClearScrollback()<cr><C-l>')

function ClearScrollback()
  local sb = vim.bo.scrollback
  vim.bo.scrollback = 1
  vim.bo.scrollback = sb
end

-- SuperCollider -----------------------------------------------------------------------------------
which.add {
  ['<leader>a'] = { name = '[a] SuperCollider', _ = 'which_key_ignore' },
}
local sc = require 'scnvim'
nmap('<leader>as', sc.start, '[a] SuperCollider [s]tart')
nmap('<leader>ap', sc.stop, '[a] SuperCollider sto[p]')
nmap('<leader>ak', sc.recompile, '[a] SuperCollider re[k]ompile')
nmap('<leader>ag', function()
  vim.cmd [[ SCNvimGenerateAssets ]]
end, '[a] SuperCollider [g]enerate')
nmap('<leader>ah', '<cmd>SCNvimHelp Home<cr>', '[a] SuperCollider [h]elp')

-- Other fixes -------------------------------------------------------------------------------------

-- I hate the regular join behavior. This skips the extra space.
-- nmap('J', '<cmd>join!<cr>')

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
nmap('<Esc>', '<cmd>nohlsearch<CR>')

-- Make ^E and ^Y a bit less surgical.
-- TODO: Do these in lua. Needs to be non-recursive.
vim.cmd 'noremap ^E 5^E'
vim.cmd 'noremap ^Y 5^Y'
