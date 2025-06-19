local snacks = require "snacks"

snacks.setup {
    quickfile = { enable = true },
    bufdelete = { enable = true },
}

-- abbr ":bd" to snacks's bufdelete, and leave ":bdelete" intact.
vim.keymap.set( "ca", "bd", function() Snacks.bufdelete() end )
