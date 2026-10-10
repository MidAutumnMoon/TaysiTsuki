
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

