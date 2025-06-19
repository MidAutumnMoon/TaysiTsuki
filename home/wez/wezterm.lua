-- a lot has been taken from
-- https://github.com/daneorie/dotfiles

local wez = require 'wezterm'

local C = {}

local function unescape(url)
	return url:gsub("%%(%x%x)", hex_to_char)
end

local function basename(s)
    local current_dir = tostring( s )
    if type( s ) == "userdata" then
        current_dir = unescape(current_dir)
    end
    return current_dir:gsub("(.*[/\\])(.*)", "%2")
end

C.font = wez.font_with_fallback {
    {
        family = "Monaspace Argon",
        -- weight = "Medium",
        -- stretch = "Expanded",
    },
    -- {
    --     family = "Noto Sans CJK SC",
    --     -- weight = "Medium",
    -- },
    -- {
    --     family = "Noto Sans CJK TC",
    --     -- weight = "Medium",
    -- },
    -- {
    --     family = "Noto Sans CJK JP",
    --     -- weight = "Medium",
    -- },
}

C.font_size = 13.5
-- C.line_height = 1.12
--
C.color_scheme = "Catppuccin Macchiato"

-- C.hide_tab_bar_if_only_one_tab = true

-- C.window_background_opacity = 0.8
-- C.kde_window_background_blur = true

C.window_padding = {
    right = 0,
    left = 0,
    top = 0,
    bottom = 0,
}

C.window_decorations = "NONE"
C.show_close_tab_button_in_tabs = false
C.show_new_tab_button_in_tab_bar = false

C.use_fancy_tab_bar = true
C.tab_max_width = 25

C.window_frame = {
    font = wez.font { family = "Monaspace Argon" },
    font_size = C.font_size - 2,
}

-- Give tab a padding around its titles
wez.on( "format-tab-title", function( tab, tabs, _, _, _, max_width )
    local title = ""

    title = title .. string.format( "[%d] ", tab.tab_index + 1 )
    title = title .. basename( tab.active_pane.foreground_process_name )
    title = title .. " "
    title = title .. basename( tab.active_pane.current_working_dir.file_path )

    local leftover_width = max_width - #title
    local padding = " "
    local guaranteed_padding = padding:rep( 2 )
    local padding_left_len = math.floor( leftover_width / 2 )
    local padding_right_len = leftover_width - padding_left_len

    title = guaranteed_padding .. padding:rep( padding_left_len ) .. title
    title = title .. padding:rep( padding_right_len ) .. guaranteed_padding

    return title
end )

-- C.automatically_reload_config = false

-- maximize the window
wez.on( "gui-startup", function( cmd )
    local tab, pane, window = wez.mux.spawn_window( cmd or {} )
    window:gui_window():maximize()
end )


C.default_prog = {
    "/run/current-system/sw/bin/bash"
}

C.check_for_updates = false
C.mouse_wheel_scrolls_tabs = true
C.exit_behavior = "CloseOnCleanExit"
C.window_decorations = "NONE"

C.audible_bell = "Disabled"

C.visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = 'CursorColor',
}

C.switch_to_last_active_tab_when_closing_tab = true

C.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = { WheelUp = 1 } } },
        action = wez.action.ScrollByLine( -8 ),
    },
    {
        event = { Down = { streak = 1, button = { WheelDown = 1 } } },
        action = wez.action.ScrollByLine( 8 ),
    },
}

C.keys = {
    -- open new tab after current one
    {
        key = "t",
        mods = "CTRL|SHIFT",
        action = wez.action_callback( function( win, pane )
            local mux_win = win:mux_window()
            for _, item in ipairs( mux_win:tabs_with_info() ) do
                if item.is_active then
                    mux_win:spawn_tab {}
                    win:perform_action( wez.action.MoveTab( item.index + 1 ), pane )
                    return
                end
            end
        end )
    }
}

return C
