--
-- Global things
--

vim.g.mapleader = " "
vim.g.maplocalleader = "'"

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

-- Jump to end of line without far reach
vim.keymap.set({ "n", "o", "v" }, "<A-a>", "$")
vim.keymap.set("i", "<A-a>", "<C-o>$")

-- Move up and down without reaching for arrow key
vim.keymap.set({ "c", "i" }, "<A-j>", "<Down>")
vim.keymap.set({ "c", "i" }, "<A-k>", "<Up>")

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

vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.autowriteall = true

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
vim.opt.shortmess:append("Imr")
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
-- Flash yanked area
--

vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = "*",
    callback = function()
        vim.hl.on_yank()
    end
})

--
--  Auto save
--

local M = {}

--- @param buf integer
--- @return boolean
function M.buf_legible(buf)
    local bo = vim.bo[buf]
    return bo.modifiable
        and bo.modified
        and not bo.readonly
        and vim.api.nvim_buf_get_name(buf) ~= ""
end

--- @param buf integer
function M.save_buf(buf)
    vim.cmd.bufdo {
        "write",
        range = { buf },
        mods = { silent = true }
    }
end

vim.api.nvim_create_autocmd(
    { "InsertLeave", "TextChanged", "BufLeave" },
    {
        pattern = "*",
        nested = true,
        callback = function(opts)
            local buf = opts.buf
            if M.buf_legible(buf) then M.save_buf(buf) end
        end
    }
)

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
