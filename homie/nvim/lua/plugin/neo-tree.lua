local neotree = require "neo-tree"

neotree.setup {

  sort_case_insensitive = true,

  filesystem = {
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,
    },
    filtered_items = {
      visible = true
    },
    bind_to_cwd = true,
    window = {
      position = "left",
      width = 30
    },
  },

  buffers = {
    follow_current_file = { enabled = true },
    window = {
      width = 30,
    },
  },

  event_handlers = {
    {
      event = "neo_tree_window_after_open",
      handler = function( info )
        if vim.tbl_contains( { "left", "right" }, info.position ) then
          vim.cmd "wincmd ="
        end
      end
    },

    {
      event = "neo_tree_window_after_close",
      handler = function( info )
        if vim.tbl_contains( { "left", "right" }, info.position ) then
          vim.cmd "wincmd ="
        end
      end
    },

    {
      event = "neo_tree_buffer_enter",
      handler = function( info )
        vim.cmd [[ setlocal nonumber ]]
        vim.cmd [[ setlocal norelativenumber ]]
      end
    }
  }

}


local setkey = vim.keymap.set
local getcwd = vim.fn.getcwd

setkey( "n", "<Leader>n", function()
  vim.cmd( "Neotree focus filesystem " .. getcwd() .. " left" )
end )

setkey( "n", "<Leader><Leader>n", function()
  vim.cmd "Neotree close filesystem left"
end )

-- setkey( "n", "<Leader>b", function()
--   vim.cmd( "Neotree focus buffers " .. getcwd() .. " right" )
-- end)

setkey( "n", "<Leader><Leader>b", function()
  vim.cmd "Neotree close buffers right"
end)
