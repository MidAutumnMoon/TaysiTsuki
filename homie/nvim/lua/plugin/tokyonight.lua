local function on_highlights( hl, colors )
  hl.MsgArea = { fg = colors.none, bg = colors.none }
end

require "tokyonight" .setup {

  style = "storm",

  transparent = true,

  on_highlights = on_highlights,

  styles = {
    comments = { italic = true },
    keywords = { italic = true },
  },

  sidebars = {
    "neo-tree"
  },

}

vim.cmd.colorscheme "tokyonight"
