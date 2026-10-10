
-- Jump to end of line without far reach
vim.keymap.set({ "n", "o", "v" }, "<A-a>", "$")
vim.keymap.set("i", "<A-a>", "<C-o>$")

-- Insert a newline
vim.keymap.set("n", "<A-o>", "o<ESC>")
vim.keymap.set("n", "<A-S-o>", "O<ESC>")
vim.keymap.set("i", "<A-o>", "<C-o>o")
vim.keymap.set("i", "<A-S-o>", "<C-o>O")

-- Tabs
vim.keymap.set("n", "<A-t>", ":tabedit<CR>")
vim.keymap.set("n", "<A-w>", ":tabclose<CR>")
vim.keymap.set("n", "<A-l>", ":tabnext<CR>")
vim.keymap.set("n", "<A-h>", ":tabprevious<CR>")
vim.keymap.set("n", "<A-0>", ":tablast<CR>")
for num = 1, 9 do
    local key = string.format("<A-%d>", num)
    local cmd = string.format("%dgt", num)
    vim.keymap.set("n", key, cmd)
end

-- Cycle through splits
-- vim.keymap.set("n", "<Tab>", ":wincmd w<CR>", { silent = true })
-- vim.keymap.set("n", "<S-Tab>", ":wincmd W<CR>", { silent = true })

--
-- Options
--

vim.opt.laststatus = 3
vim.opt.smoothscroll = true
vim.opt.shell = "/bin/sh"

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 0
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.linebreak = true

vim.opt.list = true
vim.opt.listchars = {
    tab = "▷ ",
    trail = "·",
    extends = "◣",
}

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.virtualedit = "block"
vim.opt.whichwrap = "b,s,<,>,[,]"

vim.opt.fillchars = {
    eob = " "
    -- vert = " "
}
vim.filetype.add {
    extension = {
        service = "systemd",
        target = "systemd",
        path = "systemd",
        timer = "systemd",
        opml = "xml",
        mobileconfig = "xml",
        pro = "prolog",
    },
}

--
-- Edit sibling files
--

vim.keymap.set("n", "<Leader>e", function()
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local rel = vim.fs.relpath(vim.fn.getcwd(), dir)
    vim.api.nvim_feedkeys(":edit " .. "./" .. rel .. "/", "n", false)
end)

--
-- Plugins
--

if vim.fn.exists("$XDG_CURRENT_DESKTOP") == 1 then
    require "plugin.init"
end
