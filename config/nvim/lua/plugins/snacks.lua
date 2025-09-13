return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    image = {
      enabled = true,
      force = false, -- don't force if terminal doesn't support
      formats = {
        'png',
        'jpg',
        'jpeg',
        'gif',
        'bmp',
        'webp',
        'tiff',
        'heic',
        'avif',
        'mp4',
        'mov',
        'avi',
        'mkv',
        'webm',
        'pdf',
      },
      doc = {
        -- Enable image viewer for documents
        enabled = true,
        -- Render the image inline in the buffer
        inline = true,
        -- Render the image in a floating window (if inline is disabled)
        float = true,
        max_width = 80,
        max_height = 40,
        -- Set to true to conceal the image text when rendering inline
        conceal = false,
      },
      math = {
        enabled = true, -- Enable math expression rendering
        typst = {
          tpl = [[
            #set page(width: auto, height: auto, margin: (x: 2pt, y: 2pt))
            #show math.equation.where(block: false): set text(top-edge: "bounds", bottom-edge: "bounds")
            #set text(size: 12pt, fill: rgb("${color}"))
            ${header}
            ${content}]],
        },
        latex = {
          font_size = 'Large',
          packages = { 'amsmath', 'amssymb', 'amsfonts', 'amscd', 'mathtools' },
          tpl = [[
            \documentclass[preview,border=2pt,varwidth,12pt]{standalone}
            \usepackage{${packages}}
            \begin{document}
            ${header}
            { \${font_size} \selectfont
              \color[HTML]{${color}}
            ${content}}
            \end{document}]],
        },
      },
      -- Image directories to search for relative paths
      img_dirs = { 'img', 'images', 'assets', 'static', 'public', 'media', 'attachments' },
      -- Window options for image buffers
      wo = {
        wrap = false,
        number = false,
        relativenumber = false,
        cursorcolumn = false,
        signcolumn = 'no',
        foldcolumn = '0',
        list = false,
        spell = false,
        statuscolumn = '',
      },
      cache = vim.fn.stdpath 'cache' .. '/snacks/image',
      convert = {
        notify = true, -- show a notification on error
        mermaid = function()
          local theme = vim.o.background == 'light' and 'neutral' or 'dark'
          return { '-i', '{src}', '-o', '{file}', '-b', 'transparent', '-t', theme, '-s', '{scale}' }
        end,
        magick = {
          default = { '{src}[0]', '-scale', '1920x1080>' },
          vector = { '-density', 192, '{src}[0]' },
          math = { '-density', 192, '{src}[0]', '-trim' },
          pdf = { '-density', 192, '{src}[0]', '-background', 'white', '-alpha', 'remove', '-trim' },
        },
      },
    },
  },
  config = function(_, opts)
    require('snacks').setup(opts)

    -- Keymaps for image operations
    vim.keymap.set('n', '<leader>ih', function()
      require('snacks.image').hover()
    end, { desc = 'Show image at cursor (hover)' })

    vim.keymap.set('n', '<leader>ic', function()
      require('snacks.image').clear()
    end, { desc = '[C]lear all images' })

    -- Check support
    vim.keymap.set('n', '<leader>is', function()
      local file = vim.fn.expand '<cfile>'
      if require('snacks.image').supports(file) then
        vim.notify('Image format and terminal supported for: ' .. file)
      else
        vim.notify('Not supported: ' .. file, vim.log.levels.WARN)
      end
    end, { desc = 'Check image [s]upport' })
  end,
}
