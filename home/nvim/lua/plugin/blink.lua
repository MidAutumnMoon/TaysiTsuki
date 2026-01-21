local blink = require "blink-cmp"
local devicons = require "nvim-web-devicons"
local lspkind = require "lspkind"

local o = {}

o.completion = {
    keyword = { range = "prefix" },
    list = {
        selection = { preselect = true, auto_insert = true, },
    },
    trigger = {
        show_on_keyword = false,
        show_on_trigger_character = false,
    },
}

o.completion.menu = {
    border = "rounded",
    draw = {
        components = {},
        columns = {
            { "label", "label_description", gap = 1 },
            { "kind_icon", "kind", gap = 1, },
        },
    },
}

o.completion.menu.draw.components.kind_icon = {
    ellipsis = false,
    text = function ( ctx )
        local icon = ctx.kind_icon
        if vim.tbl_contains( { "Path" }, ctx.source_name ) then
            local dev_icon, _ = devicons.get_icon( ctx.label )
            if dev_icon then icon = dev_icon end
        -- else
        --     icon = lspkind.symbolic( ctx.kind, { mode = "symbol", } )
        end
        return icon .. ctx.icon_gap
    end
}

o.completion.documentation = {
    auto_show = true,
    auto_show_delay_ms = 0,
    window = { border = "rounded" },
}

o.keymap = {
    preset = "default",

    ['<C-space>'] = {
        function( cmp )
            if cmp.is_visible() then
                cmp.select_and_accept()
            else
                -- cmp.show()
                cmp.show_and_insert()
            end
        end
    },
}

o.cmdline = {
    completion = { menu = { auto_show = true } },
    keymap = { preset = "inherit", },
}

o.fuzzy = {
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

o.sources = {
    providers = {
        lsp = { timeout_ms = 1000, },
    }
}

blink.setup( o )
