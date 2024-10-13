local integrate_nvim_cmp = false

return {
  {
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    config = function()
      local copilot = require 'copilot'

      copilot.setup {
        panel = { enabled = false },
        suggestion = {
          enabled = not integrate_nvim_cmp,
          auto_trigger = true,
          hide_during_completion = true,
          debounce = 75,
          keymap = {
            -- accept = '<M-l>',
            accept = false,
            accept_word = false,
            accept_line = false,
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-]>',
          },
        },
        filetypes = {
          yaml = false,
          markdown = false,
          help = false,
          gitcommit = false,
          gitrebase = false,
          hgcommit = false,
          svn = false,
          cvs = false,
          ['.'] = false,
        },
        copilot_node_command = 'node', -- Node.js version must be > 18.x
        server_opts_overrides = {},
      }

      if integrate_nvim_cmp then
        return
      end

      local suggestion = require 'copilot.suggestion'

      vim.keymap.set('i', '<Tab>', function()
        if suggestion.is_visible() then
          suggestion.accept()
        else
          -- insert a tab
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
        end
      end, { desc = 'Copilot-enabled Tab', noremap = true })
    end,
  },
  {
    'zbirenbaum/copilot-cmp',
    enabled = integrate_nvim_cmp,
    dependencies = {
      'zbirenbaum/copilot.lua',
    },
    opts = {
      fix_pairs = true,
    },
  },
}
