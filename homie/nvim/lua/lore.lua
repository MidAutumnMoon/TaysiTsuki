local M = {}

--- A common set of filetypes to ignore
M.ExcludedFiletypes = {
    -- No files
    "",
    "nofile",
    -- Vim internal
    "help",
    -- Plugins
    "TelescopePrompt"
}


return M
