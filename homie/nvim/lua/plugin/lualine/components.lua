local M = {}

M.filename = {
    "filename",
    path = 1,
    newfile_status = true,
    symbols = {
        modified = "[+]",
        readonly = "[RO]",
        unnamed = "[No Name]",
        newfile = "[New]",
    },
    padding = {
        left = 0,
        right = 1
    }
}

M.progress_thru_buffer = {
    "%P",
    padding = {
        right = 0
    }
}

return M
