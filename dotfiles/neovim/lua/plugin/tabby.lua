local devicons = require "nvim-web-devicons"

vim.o.showtabline = 2

local theme = {
    fill = 'TabLineFill',
    head = 'TabLine',
    current_tab = { fg = "fg", bg = "NONE", style = 'italic' },
    tab = 'TabLine',
    win = 'TabLine',
    tail = 'TabLine',
}

local function build_tab_devicon( tab )
    local buf = tab.current_win().buf()
    local ftype = vim.bo[buf.id].filetype
    local icon, color = devicons.get_icon_color_by_filetype( ftype )
    local hl = nil
    if icon == nil then
        local text_icon = devicons.get_icon_by_filetype( "txt" )
        icon = text_icon
    end
    if tab.is_current() and color ~= nil then
        hl = { fg = color }
    end
    return { icon.." ", hl = hl }
end

require 'tabby.tabline' .set( function(line) return {

    line.tabs().foreach( function(tab)
        local hl = tab.is_current() and theme.current_tab or theme.tab

        return {
            tab.number(),
            build_tab_devicon( tab ),
            tab.name(),
            line.sep( '|', hl, theme.fill ),
            hl = hl,
            margin = '  ',
        }
    end ),

    hl = theme.fill,

} end )
