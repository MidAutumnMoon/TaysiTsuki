-- Ideas taken from:
-- https://github.com/lettertwo/config

local function close_floats()
    for _, winid in ipairs( vim.api.nvim_list_wins() ) do
        local winconf = vim.api.nvim_win_get_config( winid )
        if winconf.relative ~= "" then
            vim.api.nvim_win_close( winid, false )
        end
    end
end

vim.keymap.set( "n", "<Esc>", function()
    -- 1. close floating windows
    close_floats()
    -- 2. clear highlights
    vim.lsp.buf.clear_references()
    vim.cmd "nohlsearch"
end )
