local blink = require "blink-cmp"
local devicons = require "nvim-web-devicons"
local lspkind = require "lspkind"
local luasnip = require "luasnip"

local option = {}

option.completion = {
    keyword = { range = "full" },
    accept = {
        auto_brackets = {
            semantic_token_resolution = { timeout_ms = 100 },
        },
    },
    trigger = {
        show_in_snippet = true,
    },
    list = { selection = {} },
}

option.completion.list.selection = {
    -- preselect = function( ctx )
    --     return not blink.snippet_active { direction = 1 }
    -- end
    preselect = true,
}

option.completion.menu = {
    border = "rounded",
    scrollbar = false,
    draw = {
        components = {},
        columns = {
            { "label", "label_description", gap = 1 },
            { "kind_icon", "kind", gap = 1, },
        },
        treesitter = { "lsp" },
    },
}

option.completion.menu.draw.components.kind_icon = {
    ellipsis = false,
    text = function ( ctx )
        local icon = ctx.kind_icon
        if vim.tbl_contains( { "Path" }, ctx.source_name ) then
            local dev_icon, _ = devicons.get_icon( ctx.label )
            if dev_icon then icon = dev_icon end
        else
            icon = lspkind.symbolic( ctx.kind, { mode = "symbol", } )
        end
        return icon .. ctx.icon_gap
    end
}

option.completion.documentation = {
    auto_show = true,
    auto_show_delay_ms = 0,
    window = { border = "rounded" },
}

option.keymap = {
    preset = "default",
    ['<C-\\>'] = { 'select_and_accept' },
    -- To exit insert mode directly,
    -- otherwise <Esc> has to be pressed twice :/
    -- ["<Esc>"] = { "hide", "fallback" },
}

-- Cancel luasnip when exit insert mode.
-- Otherwise the next time in insert mode, hitting Tab moves the cursor
-- to last snippet, which is very annoying.
vim.api.nvim_create_autocmd( "InsertLeave", {
    pattern = '*',
    callback = function()
        luasnip.unlink_current()
    end
} )

option.cmdline = {
    completion = { menu = { auto_show = true } },
    keymap = {
        preset = "inherit",
    },
}

option.snippets = {
    preset = "luasnip",
}

option.fuzzy = {
    implementation = "rust",
    sorts = {
        -- sort items with auto-imports below imported ones
        function( a, b )
            local function has_imports( val )
                local data = val.data or {}
                local imports = data.imports
                return imports ~= nil and #imports > 0
            end

            local a_score = a.score
            local b_score = b.score
            local diff = math.abs( a_score - b_score ) / ( a_score + b_score )
            local a_auto = has_imports( a )
            local b_auto = has_imports( b )

            -- whoever is auto import got sorted below another
            if a_auto and not b_auto then
                -- b comes before a
                if diff < 0.2 then return false end
            elseif not a_auto and b_auto then
                -- a comes before b
                -- return true
                if diff < 0.2 then return true end
            end
        end,
        "score",
        "sort_text",
    },
    max_typos = function( kw )
        return 2
    end,
}

option.sources = {
    providers = {
        lsp = { timeout_ms = 1000, },
    }
}

blink.setup( option )
