(function()
    local stdpath = vim.fn.stdpath
    local lazy_repo = "https://github.com/folke/lazy.nvim.git"
    local lazy_path = stdpath( 'data' ) .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat( lazy_path ) then
        local res = vim.fn.system {
            "git", "clone", "--filter=blob:none",
            lazy_repo, lazy_path
        }
        if vim.v.shell_error ~= 0 then
            vim.api.nvim_echo( {{res}}, true, {} )
            assert( false, "Failed to install lazy.nvim" )
        end
    end
    vim.opt.rtp:prepend( lazy_path )
end)()

local lazy = require "lazy"

local __plugins = {

    --
    -- Editing
    --

    {
        "tpope/vim-repeat",
    },

    {
        "tommcdo/vim-exchange",
    },

    {
        "wellle/targets.vim",
    },

    {
        "junegunn/vim-after-object",
        config = function()
            vim.fn["after_object#enable"]( "=", ":", "|", ";", " " )
        end
    },

    {
        "junegunn/vim-easy-align",
        config = function()
            local set = vim.keymap.set
            local keyconf = { remap = true; }
            set( "n", "ga", "<Plug>(EasyAlign)", keyconf )
            set( "x", "ga", "<Plug>(EasyAlign)", keyconf )
        end
    },

    {
        "tpope/vim-surround",
    },

    {
        "echasnovski/mini.move",
        opts = { mappings = {
            -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
            left = '',
            right = '',
            down = '<M-j>',
            up = '<M-k>',

            -- Move current line in Normal mode
            line_left = '',
            line_right = '',
            line_down = '<M-j>',
            line_up = '<M-k>',
        } },
    },

    {
        "windwp/nvim-autopairs",
        config = function()
            require "plugin.autopairs"
        end
    },

    {
        "lukas-reineke/virt-column.nvim",
        opts = {
            virtcolumn = "85",
            char = "·",
        },
    },

    {
        "bullets-vim/bullets.vim"
    },

    --
    -- Navigating
    --

    {
        "https://codeberg.org/andyg/leap.nvim",
        config = function()
            require "plugin.leap"
        end
    },

    {
        "kevinhwang91/nvim-fFHighlight",
        keys = { "f", "F" },
        opts = {
            number_hint_threshold = 2,
            prompt_sign_define = { text = "f" },
        }
    },

    {
        "ibhagwan/fzf-lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require "plugin.fzf"
        end
    },

    {
        "andymass/vim-matchup",
        init = function()
            vim.g.matchup_matchparen_deferred = 1
        end
    },

    --
    -- QoL
    --

    {
        "tpope/vim-eunuch",
    },

    {
        "lukas-reineke/indent-blankline.nvim",
        event = { 'CursorHold', 'CursorMoved' },
        main = "ibl",
        opts = {
            -- laggy :/
            scope = { enabled = false }
        },
    },

    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "Isrothy/lualine-diagnostic-message"
        },
        config = function()
            require "plugin.lualine"
        end
    },

    {
        "nanozuki/tabby.nvim",
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            require "plugin.tabby"
        end
    },

    {
        "tzachar/local-highlight.nvim",
        opts = {
            animate = { enabled = false },
        },
    },

    --
    -- Completion & LSP
    --

    {
        "saghen/blink.cmp",
        version = "*",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "onsails/lspkind.nvim",
        },
        config = function ()
            require "plugin.blink"
        end
    },

    {
        "neovim/nvim-lspconfig",
    },

    --
    -- Other things
    --

    {
        "nvim-lua/plenary.nvim"
    }

}

local __config = {
    checker = { enabled = false },
    lockfile = vim.fn.stdpath('state') .. "/lazy-lock.json",
    ui = { border = "rounded", },
}

lazy.setup( __plugins, __config )

vim.cmd [[ command! P :Lazy sync ]]
