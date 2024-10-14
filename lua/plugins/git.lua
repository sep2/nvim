local function open_log_at_buffer_or_visual_block()
  -- https://www.reddit.com/r/neovim/comments/1ez1blr/comment/ljhp2zx
  local neogit = require 'neogit'

  local git_root = vim.fs.root(0, '.git')
  if type(git_root) ~= 'string' then
    print 'No git root found'
    return
  end

  local dir = vim.uv.cwd()
  if not dir then
    print 'Nil cwd'
    return
  end
  if not dir:match(git_root) then
    print 'Git root not in cwd'
    return
  end

  local current_file_name = vim.fn.expand '%:p'
  if not current_file_name or current_file_name:len() == 0 then
    print 'Current file Nil'
    return
  end

  local rooted_name = current_file_name:gsub(git_root .. '/', '', 1)

  if vim.api.nvim_get_mode().mode ~= 'n' then
    local line1 = vim.fn.getpos('v')[2]
    local line2 = vim.fn.getcurpos()[2]
    local range = '-L' .. line1 .. ',' .. line2 .. ':' .. rooted_name

    neogit.action('log', 'log_current', { range, '--no-patch' })()
  else
    local actions = require 'neogit.popups.log.actions'

    actions.log_current {
      state = { env = { files = { rooted_name } } },
      get_arguments = function()
        return { '--max-count=256', '--follow' }
      end,
      get_internal_arguments = function()
        return {
          graph = false,
          color = true,
          decorate = true,
        }
      end,
    }
  end
end

return {
  {
    'NeogitOrg/neogit',
    lazy = true,
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration

      -- Only one of these is needed.
      'nvim-telescope/telescope.nvim', -- optional
    },
    init = function()
      vim.keymap.set('n', '<leader>gg', function()
        (require 'neogit').open()
      end, { desc = '[G]it status' })

      vim.keymap.set({ 'n', 'v' }, '<leader>gl', open_log_at_buffer_or_visual_block, { desc = 'Git [l]og for selected? buffer' })
    end,
    opts = {
      graph_style = 'unicode',
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    enabled = true,
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '┃' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
        untracked = { text = '┆' },
      },
      signs_staged = {
        add = { text = '+' },
        change = { text = '┃' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
        untracked = { text = '┆' },
      },

      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        -- Actions
        -- visual mode
        map('v', '<leader>hs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'stage git hunk' })
        map('v', '<leader>hr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'reset git hunk' })
        -- normal mode
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
        map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'git [u]ndo stage hunk' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
        map('n', '<leader>hb', gitsigns.blame_line, { desc = 'git [b]lame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
        map('n', '<leader>hD', function()
          gitsigns.diffthis '@'
        end, { desc = 'git [D]iff against last commit' })
        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
        map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = '[T]oggle git show [D]eleted' })
      end,
    },
  },
}
