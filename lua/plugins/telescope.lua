return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  config = function()
    -- Two important keymaps to use while in Telescope are:
    --  - Insert mode: <c-/>
    --  - Normal mode: ?
    --
    -- This opens a window that shows you all of the keymaps for the current
    -- Telescope picker. This is really useful to discover what Telescope can
    -- do as well as how to actually do it!

    -- https://github.com/nvim-telescope/telescope.nvim/issues/2014#issuecomment-1873229658
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'TelescopeResults',
      callback = function(ctx)
        vim.api.nvim_buf_call(ctx.buf, function()
          vim.fn.matchadd('TelescopeParent', '\t\t.*$')
          vim.api.nvim_set_hl(0, 'TelescopeParent', { link = 'Comment' })
        end)
      end,
    })

    local function filenameFirst(_, path)
      local tail = vim.fs.basename(path)
      local parent = vim.fs.dirname(path)
      if parent == '.' then
        return tail
      end
      return string.format('%s\t\t%s', tail, parent)
    end

    -- https://github.com/nvim-telescope/telescope.nvim/issues/2014#issuecomment-1998342873
    local function telescope_symbol_entry_maker()
      local entry_display = require 'telescope.pickers.entry_display'

      local symbol_to_icon_map = {
        ['class'] = { icon = ' ', hi = 'TelescopeResultClass' },
        ['type'] = { icon = ' ', hi = 'TelescopeResultClass' },
        ['struct'] = { icon = ' ', hi = 'TelescopeResultStruct' },
        ['enum'] = { icon = ' ', hi = 'TelescopeResultClass' },
        ['union'] = { icon = ' ', hi = 'TelescopeResultClass' },
        ['interface'] = { icon = ' ', hi = 'TelescopeResultMethod' },
        ['method'] = { icon = ' ', hi = 'TelescopeResultMethod' },
        ['function'] = { icon = 'ƒ ', hi = 'TelescopeResultFunction' },
        ['constant'] = { icon = ' ', hi = 'TelescopeResultConstant' },
        ['field'] = { icon = ' ', hi = 'TelescopeResultField' },
        ['property'] = { icon = ' ', hi = 'TelescopeResultField' },
      }

      local displayer = entry_display.create {
        separator = ' ',
        items = {
          { width = 2 },
          { remaining = true },
        },
      }

      local entry_maker = require('telescope.make_entry').gen_from_lsp_symbols {}

      return function(line)
        local originalEntryTable = entry_maker(line)
        originalEntryTable.display = function(entry)
          local kind_and_higr = symbol_to_icon_map[entry.symbol_type:lower()] or { icon = ' ', hi = 'TelescopeResultsNormal' }
          local dot_idx = entry.symbol_name:reverse():find '%.' or entry.symbol_name:reverse():find '::'
          local symbol, qualifiier

          if dot_idx == nil then
            symbol = entry.symbol_name
            qualifiier = entry.filename
          else
            symbol = entry.symbol_name:sub(1 - dot_idx)
            qualifiier = entry.symbol_name:sub(1, #entry.symbol_name - #symbol - 1)
          end

          return displayer {
            { kind_and_higr.icon, kind_and_higr.hi },
            string.format('%s\t\tin %s', symbol, qualifiier),
          }
        end

        return originalEntryTable
      end
    end

    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`
    require('telescope').setup {
      -- defaults = {
      --   mappings = {
      --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
      --   },
      -- },
      pickers = {
        lsp_dynamic_workspace_symbols = {
          entry_maker = telescope_symbol_entry_maker(),
        },
        lsp_references = {},
        find_files = {
          path_display = filenameFirst,
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'

    local function project_files() -- Search for files in the current project
      local git_root = vim.fs.root(0, '.git')
      if type(git_root) == 'string' then
        builtin.git_files { prompt_title = 'Git Files' }
      else
        builtin.find_files()
      end
    end

    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch existing [b]uffers' })
    vim.keymap.set('n', '<leader>sc', builtin.git_bcommits, { desc = '[S]earch [c]ommits for current buffer' })
    vim.keymap.set('n', '<leader><leader>', project_files, { desc = '[ ] Search Project Files' })

    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to Telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = true,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- It's also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
