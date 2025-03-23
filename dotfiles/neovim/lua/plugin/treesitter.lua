require "nvim-treesitter.configs".setup {

    highlight = {
        enable = true,
        disable = {
            -- Broken
            "ssh_config",
        },
    },

--     #incremental_selection = {
--         enable = true,
--         keymaps = {
--             init_selection = "<C-space>",
--             node_incremental = "<C-space>",
--             scope_incremental = true,
--             node_decremental = "<bs>",
--         },
--     },

    indent = {
        enable = true,
        disable = {
            "ruby",
            "nix",
        },
    },

    matchup = {
        enable = true
    },

    endwise = {
        enable = true
    },

}

vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldtext = ""
