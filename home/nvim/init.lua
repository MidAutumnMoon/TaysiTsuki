--
-- Global things
--

vim.g.mapleader = " "
vim.g.maplocalleader = "\\\\"

vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provide = 0

require "plugin.init"

--
-- Keymaps
--

-- Quit vim
vim.keymap.set(
    -- save and quit
    "n", "<Leader>q",
    function()
        vim.cmd.wall()
        vim.cmd.qa()
    end
)
vim.keymap.set(
    -- force quit without save
    "n", "<LocalLeader>q",
    function()
        vim.cmd.qa { bang = true }
    end
)

-- Free movement
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Select all lines
vim.keymap.set("n", "<Leader>A", "ggVG")

-- Jump to end of line without far reach
vim.keymap.set({"n", "o", "v"}, "<A-a>", "$")
vim.keymap.set("i", "<A-a>", "<C-o>$")

-- Move up and down without reaching for arrow key
vim.keymap.set({"c", "i"}, "<A-j>", "<Down>")
vim.keymap.set({"c", "i"}, "<A-k>", "<Up>")

-- "shift+5" is out of reach
vim.keymap.set({"n", "o", "v"}, "<Enter>", "%")

-- Scroll faster
vim.keymap.set("n", "<C-e>", "3<C-e>")
vim.keymap.set("n", "<C-y>", "3<C-y>")

-- Insert a newline
vim.keymap.set("n", "<A-o>", "o<ESC>")
vim.keymap.set("n", "<A-S-o>", "O<ESC>")
vim.keymap.set("i", "<A-o>", "<C-o>o")
vim.keymap.set("i", "<A-S-o>", "<C-o>O")

-- Tabs
vim.keymap.set("n", "<A-t>", ":tabedit<CR>")
vim.keymap.set("n", "<A-w>", ":tabclose<CR>")
vim.keymap.set("n", "<A-]>", ":tabnext<CR>")
vim.keymap.set("n", "<A-[>", ":tabprevious<CR>")
vim.keymap.set("n", "<A-0>", ":tablast<CR>")
for num = 1, 9 do
    local key = string.format("<A-%d>", num)
    local cmd = string.format("%dgt", num)
    vim.keymap.set("n", key, cmd)
end
