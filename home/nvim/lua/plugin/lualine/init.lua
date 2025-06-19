local lualine = require "lualine"

local cpnts = require "plugin.lualine.components"
local filename = cpnts.filename
local progress_thru_buffer = cpnts.progress_thru_buffer

local sources = require "plugin.lualine.sources"


local sections = {
    lualine_a = { filename },
    lualine_b = { },
    lualine_c = {
        { "diff", source = sources.gitsigns },
        {
            "diagnostic-message",
            icons = {
                error = "E:",
                warn = "W:",
                info = "I:",
                hint = "H:",
            },
            first_line_only = true,
        }
    },
    lualine_x = {
        {
            "encoding",
            cond = function()
                return vim.o.encoding ~= "utf-8"
            end
        },
        {
            "fileformat",
            cond = function()
                return vim.bo.fileformat ~= "unix"
            end
        },
        "filetype"
    },
    lualine_y = { "location" },
    lualine_z = { progress_thru_buffer }
}


local inactive_sections = {
    lualine_a = { },
    lualine_b = { },
    lualine_c = { filename },
    lualine_x = {
        {
            "encoding",
            cond = function()
                return vim.o.encoding ~= "utf-8"
            end
        },
        {
            "fileformat",
            cond = function()
                return vim.bo.fileformat ~= "unix"
            end
        },
        "filetype"
    },
    lualine_y = { "location" },
    lualine_z = { progress_thru_buffer }
}


local NONE = { bg = "NONE" }

lualine.setup {

    options = {

        icons_enabled = true,
        component_separators = "",
        section_separators = "",
        refresh = { statusline = 200 },

        theme = {
            normal = {
                a = NONE, b = NONE, c = NONE,
                x = NONE, y = NONE, z = NONE,
            },
        },

    },

    sections = sections,
    inactive_sections = inactive_sections
}
