-- General
swayimg.decoration = true
swayimg.antialiasing = false

-- Image list
swayimg.imagelist.adjacent = true
swayimg.imagelist.fsmon = true

-- Text overlay
swayimg.text.timeout = 3
swayimg.text.status_timeout = 3

-- Viewer
swayimg.viewer.set_window_background(0xff292828)
swayimg.viewer.set_image_chessboard(16, 0xff333333, 0xff4c4c4c) -- TODO: adjust size/colors to preference
swayimg.viewer.default_scale = "fit"
swayimg.viewer.history = 30
swayimg.viewer.preload = 5

-- Gallery
swayimg.gallery.preload = true

-- Viewer text scheme
swayimg.viewer.set_text("topleft", {
    "File:\t{name}",
    "Size:\t{frame.width}x{frame.height}",
    "Disk:\t{sizehr}",
    -- exif: no single-field equivalent in Lua API; use {meta.*} tags
    -- e.g. "Camera:\t{meta.Exif.Photo.Model}"
})
-- top_right = none -> omitted
swayimg.viewer.set_text("bottomleft", {
    "Index:\t{list.index}/{list.total}",
    "Scale:\t{scale}%",
})
swayimg.viewer.set_text("bottomright", {
    -- status: not available as template; set via swayimg.text.status field
    "Frame:\t{frame.index}/{frame.total}",
})

-- Viewer key bindings
swayimg.viewer.bind_reset()

swayimg.viewer.on_key("Left", function()
    swayimg.viewer.open("prev")
end)
swayimg.viewer.on_key("Right", function()
    swayimg.viewer.open("next")
end)
swayimg.viewer.on_key("bracketright", function()
    swayimg.viewer.open("next")
end)
swayimg.viewer.on_key("bracketleft", function()
    swayimg.viewer.open("prev")
end)
swayimg.viewer.on_key("Escape", function()
    swayimg.exit()
end)
swayimg.viewer.on_key("Home", function()
    swayimg.viewer.open("first")
end)
swayimg.viewer.on_key("End", function()
    swayimg.viewer.open("last")
end)
-- Multiplicative zoom step: each input is a constant perceptual ratio,
-- so zoom feels flat instead of slowing down at high scales.
-- (1.2 == the old +0.2 step at 100%.)
local zoom_factor = 1.2

swayimg.viewer.on_key("Minus", function()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale / zoom_factor)
end)
swayimg.viewer.on_key("Equal", function()
    local mouse = swayimg.get_mouse_pos()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale * zoom_factor, mouse.x, mouse.y)
end)
swayimg.viewer.on_mouse("ScrollUp", function()
    local mouse = swayimg.get_mouse_pos()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale * zoom_factor, mouse.x, mouse.y)
end)
swayimg.viewer.on_mouse("ScrollDown", function()
    local mouse = swayimg.get_mouse_pos()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale / zoom_factor, mouse.x, mouse.y)
end)
swayimg.viewer.on_key("f", function()
    swayimg.fullscreen = not swayimg.fullscreen
end)
swayimg.viewer.on_key("j", function()
    local pos = swayimg.viewer.get_position()
    swayimg.viewer.set_abs_position(pos.x, pos.y + 10)
end)
swayimg.viewer.on_key("k", function()
    local pos = swayimg.viewer.get_position()
    swayimg.viewer.set_abs_position(pos.x, pos.y - 10)
end)
swayimg.viewer.on_key("h", function()
    local pos = swayimg.viewer.get_position()
    swayimg.viewer.set_abs_position(pos.x - 10, pos.y)
end)
swayimg.viewer.on_key("l", function()
    local pos = swayimg.viewer.get_position()
    swayimg.viewer.set_abs_position(pos.x + 10, pos.y)
end)
swayimg.viewer.on_key("n", function()
    swayimg.viewer.animation = not swayimg.viewer.animation
end)
swayimg.viewer.on_key("i", function()
    swayimg.text.visible = not swayimg.text.visible
end)
swayimg.viewer.on_key("a", function()
    swayimg.viewer.set_fix_scale("fit")
end)
swayimg.viewer.on_key("w", function()
    swayimg.viewer.set_fix_scale("width")
end)
swayimg.viewer.on_key("p", function()
    swayimg.viewer.set_fix_scale("keep")
end)
swayimg.viewer.on_key("o", function()
    local img = swayimg.viewer.get_image()
    if img then
        os.execute(string.format("fish -c \"open (dirname '%s')\"", img.path))
    end
end)
swayimg.viewer.on_key("c", function()
    local img = swayimg.viewer.get_image()
    if img then
        os.execute(string.format(
            "printf 'file://%s\\n' | wl-copy -t text/uri-list",
            img.path
        ))
    end
end)

-- Viewer mouse bindings
swayimg.viewer.on_mouse("MouseRight", function()
    swayimg.viewer.open("next")
end)
swayimg.viewer.drag_button = "MouseLeft"
