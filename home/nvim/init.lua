--
-- Global things
--

vim.g.mapleader = " "
vim.g.maplocalleader = "'"

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
vim.keymap.set({ "n", "o", "v" }, "<A-a>", "$")
vim.keymap.set("i", "<A-a>", "<C-o>$")

-- Move up and down without reaching for arrow key
vim.keymap.set({ "c", "i" }, "<A-j>", "<Down>")
vim.keymap.set({ "c", "i" }, "<A-k>", "<Up>")

-- "shift+5" is out of reach
vim.keymap.set({ "n", "o", "v" }, "<Enter>", "%")

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
vim.keymap.set("n", "<Tab>", ":wincmd w<CR>", { silent = true })
vim.keymap.set("n", "<S-Tab>", ":wincmd W<CR>", { silent = true })

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
-- Restore cursor position
--

vim.api.nvim_create_autocmd("BufReadPost", {
    desc = "Restore cursor position",
    callback = function(opts)
        local buf = opts.buf

        local exclude_ft = {
            "gitcommit",
            "gitrebase",
            "commit",
            "svn",
            "helo"
        }
        if vim.tbl_contains(exclude_ft, vim.bo[buf].filetype) then
            return
        end


        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        local line_count = vim.api.nvim_buf_line_count(buf)
        local win = vim.fn.bufwinid(buf)

        local row = mark[1]
        if row > 0 and row <= line_count then
            pcall(vim.api.nvim_win_set_cursor, win, mark)
        end
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
-- Better ESC
--

--- @diagnostic disable-next-line
local M = {}

function M.close_floating()
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
        local winconf = vim.api.nvim_win_get_config(winid)
        if winconf.relative ~= "" then
            vim.api.nvim_win_close(winid, false)
        end
    end
end

vim.keymap.set(
    "n", "<Esc>",
    function()
        -- 1. close floating windows
        M.close_floating()
        -- 2. clear highlights
        vim.lsp.buf.clear_references()
        vim.cmd "nohlsearch"
    end
)

--
-- Plugins
--

if vim.fn.exists("$XDG_CURRENT_DESKTOP") == 1 then
    require "plugin.init"
end
