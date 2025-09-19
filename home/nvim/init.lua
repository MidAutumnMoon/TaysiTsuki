--
-- Global things
--

vim.g.mapleader = " "
vim.g.maplocalleader = "\\\\"

vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provide = 0

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

--
-- Options
--

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "n"
vim.opt.lazyredraw = true
vim.opt.timeoutlen = 300
vim.opt.updatetime = 1000
vim.opt.laststatus = 3
vim.opt.scrolloff = 10
vim.opt.smoothscroll = true
vim.opt.shell = "/bin/sh"

vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.autowriteall = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 0
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.autoindent = true

vim.opt.list = true
vim.opt.listchars = {
    tab = "▷ ",
    trail = "·",
    extends = "◣",
}

do
    local state_dir = vim.fn.stdpath "state"
    vim.opt.swapfile = true
    vim.opt.directory = state_dir .. "/swap//"
    vim.opt.writebackup = true
    vim.opt.backup = false
    vim.opt.backupdir = state_dir .. "/backup//"
    vim.opt.undofile = true
    vim.opt.undodir = state_dir .. "/undo//"
end

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.shortmess:append( "Imr" )
vim.opt.formatoptions:append("1,j")
vim.opt.virtualedit = "block"
vim.opt.whichwrap = "b,s,<,>,[,]"

vim.opt.completeopt = "menuone,preview,longest"
vim.opt.showbreak = "↳ "
vim.opt.breakindent = true
vim.opt.breakindentopt = "sbr"

vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.visualbell = true
vim.opt.fillchars = {
    eob = " "
    -- vert = " "
}
vim.opt.signcolumn = "yes:1"
vim.opt.nrformats = "hex,bin,unsigned"
vim.opt.winborder = "rounded"
vim.opt.wildmenu = true
vim.opt.wildmode = "full:lastused"

--
-- Plugins
--

require "plugin.init"
