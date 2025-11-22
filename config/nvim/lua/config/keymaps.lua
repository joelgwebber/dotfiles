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

local function tmap(lhs, rhs, desc)
  map('t', lhs, rhs, desc)
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
nmap('<leader>w=', '<C-w>=', '[w]indow [=]ize')

-- <C-hjkl> window navigation
nmap('<C-h>', '<C-w><C-h>', 'focus left window')
nmap('<C-l>', '<C-w><C-l>', 'focus right window')
nmap('<C-j>', '<C-w><C-j>', 'focus lower window')
nmap('<C-k>', '<C-w><C-k>', 'focus upper window')

-- <C-ldur> window resizing
nmap('<C-Left>', '4<C-w><lt>', 'Decrease window hsize')
nmap('<C-Right>', '4<C-w>>', 'Increase window vsize')
nmap('<C-Down>', '2<C-w>-', 'Decrease window hsize')
nmap('<C-Up>', '2<C-w>+', 'Increase window vsize')

-- Terminal mode window resizing
tmap('<C-Left>', '<C-\\><C-n>4<C-w><lt>a', 'Decrease window width (terminal)')
tmap('<C-Right>', '<C-\\><C-n>4<C-w>>a', 'Increase window width (terminal)')
tmap('<C-Down>', '<C-\\><C-n>2<C-w>+a', 'Increase window height (terminal)')
tmap('<C-Up>', '<C-\\><C-n>2<C-w>-a', 'Decrease window height (terminal)')

-- Buffer controls ---------------------------------------------------------------------------------
which.add {
  { '<leader>b', group = '[b]uffer' },
}
nmap('<leader>bd', '<cmd>bdelete<cr>', '[b]uffer [d]elete')
nmap('<leader>bD', '<cmd>bdelete!<cr>', '[b]uffer [D]elete!')
nmap('<leader>by', '<cmd>let @+=expand("%:p")<cr>', '[b]uffer [y]ank path')
nmap('<leader>bo', function()
  local filepath = vim.fn.expand('%:p')
  if filepath == '' then
    vim.notify('No file to open', vim.log.levels.WARN)
    return
  end
  require('config.utils').open_with_system(filepath)
end, '[b]uffer [o]pen with OS')
nmap('<leader>br', function()
  local current_name = vim.fn.expand '%:t'
  vim.ui.input({ prompt = 'Rename buffer: ', default = current_name }, function(new_name)
    if new_name and new_name ~= '' then
      vim.api.nvim_buf_set_name(0, new_name)
    end
  end)
end, '[b]uffer [r]ename')

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
nmap('K', function()
  vim.lsp.buf.hover { border = 'single' }
end, 'Hover Documentation')

-- Outline
nmap('<leader>co', '<cmd>AerialOpen float<cr>', '[c]ode [o]utline (float)')
nmap('<leader>cO', '<cmd>AerialToggle<cr>', '[c]ode [O]utline (pin)')

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
nmap('<M-,>', function()
  dial.manipulate('decrement', 'normal')
end, 'Decrement value')
nmap('<M-.>', function()
  dial.manipulate('increment', 'normal')
end, 'Increment value')

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
  { '<leader>T', group = '[T]est' },
}

-- Terminal -----------------------------------------------------------------------------------------
which.add {
  { '<leader>t', group = '[t]erminal' },
}
nmap('<Leader>TT', '<cmd>Neotest summary<cr>', '[T]est show [T]ests')
nmap('<Leader>TR', '<cmd>Neotest run<cr>', '[T]est [R]un')
nmap('<Leader>TO', '<cmd>Neotest output-panel<cr>', '[T]est [O]utput')

-- Debugger ----------------------------------------------------------------------------------------
which.add {
  { '<leader>u', group = 'deb[u]g' },
}
nmap('<Leader>uu', '<cmd>DapUiToggle<cr>', 'deb[u]g [u]i toggle')
nmap('<Leader>ur', '<cmd>DapContinue<cr>', 'deb[u]g [r]un / continue')
nmap('<Leader>ut', '<cmd>DapTerminate<cr>', 'deb[u]g [t]erminate')
nmap('<Leader>ub', '<cmd>DapToggleBreakpoint<cr>', 'deb[u]g toggle [b]reakpoint')
nmap('<F8>', '<cmd>DapContinue<cr>', 'debug continue')
nmap('<F10>', '<cmd>DapStepOver<cr>', 'debug step over')
nmap('<F11>', '<cmd>DapStepInto<cr>', 'debug step into')
nmap('S-<F11>', '<cmd>DapStepOut<cr>', 'debug step out')

-- Terminal ----------------------------------------------------------------------------------------

-- Clear scrollback hack for the terminal.
-- Map the special escape sequence from kitty for Ctrl+Shift+L
tmap('<C-S-l>', '<cmd>lua ClearScrollback()<cr><C-l>', 'Clear terminal and scrollback')

function ClearScrollback()
  local sb = vim.bo.scrollback
  vim.bo.scrollback = 1
  vim.bo.scrollback = sb
end

tmap('<C-h>', '<C-\\><C-n><C-w>h', 'focus left window (terminal)')
tmap('<C-j>', '<C-\\><C-n><C-w>j', 'focus lower window (terminal)')
tmap('<C-k>', '<C-\\><C-n><C-w>k', 'focus upper window (terminal)')
tmap('<C-l>', '<C-\\><C-n><C-w>l', 'focus right window (terminal)')

-- Music -------------------------------------------------------------------------------------------
which.add {
  { '<leader>m', group = '[m]usic' },
}

-- SuperCollider
which.add {
  { '<leader>mS', group = '[S]uperCollider' },
}
local sc = require 'scnvim'
nmap('<leader>mSs', sc.start, '[s]tart')
nmap('<leader>mSp', sc.stop, 'sto[p]')
nmap('<leader>mSk', sc.recompile, 're[k]ompile')
nmap('<leader>mSg', function()
  vim.cmd [[ SCNvimGenerateAssets ]]
end, '[g]enerate')
nmap('<leader>mSh', '<cmd>SCNvimHelp Home<cr>', '[h]elp')

-- AI Tools ----------------------------------------------------------------------------------------
which.add {
  { '<leader>a', group = '[a]i' },
}

-- Custom Copilot accept with debugging
vim.keymap.set('i', '<C-Enter>', function()
  require('config.utils').debug_log('C-Enter pressed in insert mode')
  local suggestion = require('copilot.suggestion')
  if suggestion.is_visible() then
    require('config.utils').debug_log('Suggestion is visible, accepting')
    suggestion.accept()
  else
    require('config.utils').debug_log('No suggestion visible to accept')
    -- Fallback to normal Enter behavior
    return '<Enter>'
  end
end, { expr = true, desc = 'Accept Copilot suggestion (with debug)' })

-- Debug commands for Copilot troubleshooting
vim.api.nvim_create_user_command('CopilotDebug', function()
  require('config.utils').debug_copilot()
end, { desc = 'Show Copilot debug information' })

vim.api.nvim_create_user_command('CopilotCheckKeymap', function()
  local utils = require('config.utils')
  local keymap = utils.check_keymap('i', '<C-Enter>')
  if keymap then
    local info = {
      'C-Enter keymap found:',
      '  RHS: ' .. (keymap.rhs or 'function'),
      '  Description: ' .. (keymap.desc or 'none'),
      '  Buffer: ' .. (keymap.buffer and 'local' or 'global'),
      '  Silent: ' .. tostring(keymap.silent or false),
    }
    vim.notify(table.concat(info, '\n'), vim.log.levels.INFO)
  else
    vim.notify('No C-Enter keymap found in insert mode!', vim.log.levels.WARN)
  end
end, { desc = 'Check if C-Enter keymap exists' })

vim.api.nvim_create_user_command('CopilotTestAccept', function()
  require('config.utils').debug_log('Manual test of Copilot accept triggered')
  local suggestion = require('copilot.suggestion')
  if suggestion.is_visible() then
    vim.notify('Suggestion visible - accepting', vim.log.levels.INFO)
    suggestion.accept()
  else
    vim.notify('No suggestion visible', vim.log.levels.WARN)
  end
end, { desc = 'Manually test Copilot accept function' })

-- Notifications -----------------------------------------------------------------------------------
nvmap('<leader>nc', function()
  require('mini.notify').clear()
end, '[n]otify [c]lear')

-- Other fixes -------------------------------------------------------------------------------------

-- Disabled: I think this might be making some large files slow.
vim.opt.hlsearch = false

-- Make ^E and ^Y a bit less surgical.
-- TODO: Do these in lua. Needs to be non-recursive.
vim.cmd 'noremap ^E 5^E'
vim.cmd 'noremap ^Y 5^Y'
