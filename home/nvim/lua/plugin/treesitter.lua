require "nvim-treesitter".setup {

    -- highlight = {
    --     enable = true,
    --     disable = {
    --         -- Broken
    --         "ssh_config",
    --     },
    -- },

    -- indent = {
    --     enable = true,
    --     disable = {
    --         "ruby",
    --         "nix",
    --         "elixir", "heex",
    --     },
    -- },

    install_dir = "/home/teapot/wow"

}

vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldtext = ""
