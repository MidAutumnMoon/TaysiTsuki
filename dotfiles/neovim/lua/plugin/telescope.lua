local telescope = require "telescope"
local action = require "telescope.actions"
local builtin = require "telescope.builtin"

telescope.setup {
    defaults = {
        preview = {
            filesize_limit = 10, -- MiB
            treesitter = false
        },
        mappings = {
            i = { ["<Esc>"] = action.close }
        },
    },
}

local BatchSetKeymaps = require "nus".BatchSetKeymaps

BatchSetKeymaps { "n" } {
    -- f : find
    ["<Leader>f"] = function()
        local cmd = {
            "fd",
            "--type=file",
            "--color=never",
            "--hidden",
            "--exclude=.git/",
        }
        builtin.find_files { find_command = cmd }
    end,

    -- F : old "F"ile
    ["<Leader>F"] = builtin.oldfiles,

    -- <Enter> : Similar to <Alt-Enter>
    ["<Leader><Enter>"] = builtin.buffers,

    -- l : Lines
    ["<Leader>l"] = function ()
        builtin.current_buffer_fuzzy_find {
            skip_empty_lines = true,
        }
    end,

    -- d : Diagnostics
    ["<Leader>d"] = builtin.diagnostics,

    -- s : Symbols
    ["<Leader>s"] = builtin.treesitter,
}
