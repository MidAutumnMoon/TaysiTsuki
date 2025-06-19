local leap = require "leap"

leap.opts.highlight_unlabeled_phase_one_targets = true
leap.opts.safe_labels = {}


local Modes = { "n", "x", "o" }

-- "s" prefix conflicts with mini.surround
vim.keymap.set( Modes, "ss", "<Plug>(leap-forward-to)" )
vim.keymap.set( Modes, "SS", "<Plug>(leap-backward-to)" )
vim.keymap.set( Modes, "gl", "<Plug>(leap-from-window)" )
