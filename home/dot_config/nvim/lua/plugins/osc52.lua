-- OSC52 clipboard, for remote sessions only.
--
-- OSC52 is a terminal escape sequence: nvim hands the text to the terminal and
-- the terminal puts it on the clipboard. That is the only way to reach the
-- *local* clipboard from a shell on another machine, so over SSH it is the
-- right answer.
--
-- Locally it is strictly worse, and it silently breaks pasting. The `paste`
-- function below -- straight from the plugin's README -- does not read the
-- system clipboard at all; it returns nvim's own unnamed register. Reading the
-- clipboard over OSC52 means asking the terminal to answer an OSC 52 query,
-- which terminals disable by default because it lets anything on the tty
-- exfiltrate your clipboard. So the README fakes it. Installing this provider
-- on a desktop therefore replaces a working bidirectional provider
-- (wl-copy/wl-paste, which nvim autodetects) with a write-only one.
--
-- Hence the `cond` gate. See dots-0bce.
return {
  'ojroques/nvim-osc52',
  cond = function()
    return vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
  end,
  config = function()
    require('osc52').setup {
      max_length = 0, -- Maximum length of selection (0 for no limit)
      silent = false, -- Disable message on successful copy
      trim = false, -- Trim surrounding whitespace before copy
    }

    -- Set up as default clipboard provider
    local function copy(lines, _)
      require('osc52').copy(table.concat(lines, '\n'))
    end

    -- NOT a real clipboard read -- see the note at the top. Over SSH this at
    -- least makes `"+p` return what you last yanked in this nvim, which is the
    -- best available without terminal OSC 52 query support.
    local function paste()
      return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
    end

    vim.g.clipboard = {
      name = 'osc52',
      copy = { ['+'] = copy, ['*'] = copy },
      paste = { ['+'] = paste, ['*'] = paste },
    }
  end,
}
