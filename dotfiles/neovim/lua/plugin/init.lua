--
-- Bootstrap Lazy.nvim
--

(function()

    local stdpath = vim.fn.stdpath
    local lazy_path = stdpath( 'data' ) .. "/lazy/lazy.nvim"

    vim.opt.rtp:prepend( lazy_path )

end)()

local plugins = {

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
        keys = "ca",
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
        opts = {},
    },

    {
        "windwp/nvim-autopairs",
        event = { "InsertEnter" },
        config = function()
            require "plugin.autopairs"
        end
    },

    {
        "windwp/nvim-ts-autotag",
        after = "nvim-treesitter",
        opts = {},
    },

    {
        "eraserhd/parinfer-rust",
        ft = {
            "racket",
            "lisp",
            "scheme"
        },
        init = function()
            local user = vim.loop.os_getenv( "USER" )
            assert( user and user ~= "", "Can't read $USER" )
            local profile = "/etc/profiles/per-user/" .. user
            local dylib = profile .. "/lib/libparinfer_rust.so"
            local stat = vim.loop.fs_stat( dylib )
            assert( stat and stat.type == "file", "Dylib not exists" )
            vim.g.parinfer_dylib_path = dylib
        end
    },

    { "benknoble/vim-racket" },

    {
        "lukas-reineke/virt-column.nvim",
        opts = {
            virtcolumn = "85",
            char = "·",
        },
    },

    --
    -- Navigating
    --

    {
        "ggandor/leap.nvim",
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
        "nvim-telescope/telescope.nvim",
        keys = { "<Leader>" },
        cmd = "Telescope",
        config = function()
            require "plugin.telescope"
        end
    },

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons"
        },
        cmd = "Neotree",
        event = { "CursorMoved", "CursorHold" },
        config = function()
            require "plugin.neo-tree"
        end
    },

    {
        "andymass/vim-matchup",
        after = "nvim-treesitter",
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
        opts = { },
    },

    {
        "lewis6991/gitsigns.nvim",
        name = "gitsigns",
        event = { "CursorHold", "CursorMoved" },
        opts = {
            signs = {
                add = { text = "+" },
                change = { text = '~' },
                delete = { text = '-' }
            }
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
        "HiPhish/rainbow-delimiters.nvim",
        main = "rainbow-delimiters.setup",
        submodules = false,
        opts = {},
    },

    {
        "folke/snacks.nvim",
        config = function()
            require "plugin.snacks"
        end
    },

    --
    -- Completion & LSP
    --

    -- {
    --     "hrsh7th/nvim-cmp",
    --     dependencies = {
    --         "hrsh7th/cmp-nvim-lsp",
    --         "hrsh7th/cmp-buffer",
    --         "hrsh7th/cmp-nvim-lsp-signature-help",
    --         "https://codeberg.org/FelipeLema/cmp-async-path",
    --         "hrsh7th/cmp-cmdline",
    --         "saadparwaiz1/cmp_luasnip",
    --         "onsails/lspkind.nvim",
    --     },
    --     config = function()
    --         require "plugin.cmp"
    --     end
    -- },

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
        config = function()
            require "plugin.lspconfig"
        end
    },

    {
        "L3MON4D3/LuaSnip",
        -- dependencies = { "honza/vim-snippets" },
        config = function()
            require( "luasnip.loaders.from_snipmate" ).lazy_load { }
        end
    },

    --
    -- Treesitter
    --

    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        name = "treesitter",
        config = function()
            require "plugin.treesitter"
        end
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        opts = {
            max_lines = 3,
        },
    },

    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        after = "nvim-treesitter",
    },

    {
        "RRethy/nvim-treesitter-endwise",
        after = "nvim-treesitter",
    },

    --
    -- Languages
    --

    {
        "isobit/vim-caddyfile",
        ft = { "caddyfile" },
    },

    {
        "imsnif/kdl.vim",
        ft = { "kdl" }
    },

    {
        "bellinitte/uxntal.vim"
    },

    --
    -- Colorschemes
    --

    -- {
    --     "folke/tokyonight.nvim",
    --     enabled = false,
    --     config = function() require "plugin.tokyonight" end
    -- },

    -- {
    --     "catppuccin/nvim",
    --     name = "catppuccin",
    --     config = function()
    --         require "catppuccin".setup {
    --             flavour = "mocha",
    --             transparent_background = true,
    --         }
    --         vim.cmd.colorscheme "catppuccin"
    --     end
    -- },

    -- {
    --     "scottmckendry/cyberdream.nvim",
    --     config = function()
    --         require "cyberdream".setup {
    --             transparent = true,
    --             cache = true,
    --         }
    --         vim.cmd.colorscheme "cyberdream"
    --     end
    -- },

    {
        "olimorris/onedarkpro.nvim",
        config = function()
            require "onedarkpro" .setup {
                options = {
                    cursorline = true,
                    lualine_transparency = true,
                    transparency = true,
                }
            }
            vim.cmd "colorscheme onedark_vivid"
        end
    },

    --
    -- Other things
    --

    {
        "nvim-lua/plenary.nvim"
    }

}

local config = {

    checker = { enabled = false },

    lockfile = vim.fn.stdpath('state') .. "/lazy-lock.json",

    -- Don't reset runtimepath because treesitter parsers are
    -- externally managed using nix, and is passed to nvim
    -- using $XDG_DATA_DIRS.
    performance = {
        rtp = { reset = false },
    },

    ui = {
        border = "rounded",
    },

}

config.performance.rtp.disabled_plugins = {
    "gzip",
    "matchit",
    "matchparen",
    "netrwPlugin",
    "tarPlugin",
    "tohtml",
    "tutor",
    "zipPlugin",
}

require "lazy".setup( plugins, config )


vim.cmd [[ command! P :Lazy sync ]]
