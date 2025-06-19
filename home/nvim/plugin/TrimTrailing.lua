local ExcludedFiletypes = require "lore".ExcludedFiletypes

local config = {
    IgnoredFiles = { }
}

local M = {}

--- @param buf number
function M.validate_buffer( buf )
    local bo = vim.bo[buf]
    local name = vim.fs.basename(
        vim.api.nvim_buf_get_name( buf )
    )
    return (
        bo.modifiable
        and not vim.tbl_contains( ExcludedFiletypes, bo.ft )
        and not vim.tbl_contains( config.IgnoredFiles, name )
    )
end

--- @param buf integer
function M.trim( buf )
    if not M.validate_buffer( buf ) then
        return
    end

    local saved_view = vim.fn.winsaveview()

    vim.cmd [[
        keepjumps keeppatterns silent! %s/\s\+$//e
    ]]

    vim.fn.winrestview( saved_view )
end

vim.keymap.set(
    "n", "<LocalLeader>\\",
    function() M.trim( 0 ) end
)

vim.api.nvim_create_autocmd( {
    "ExitPre",
    "BufLeave",
    "WinLeave",
}, {
    pattern = "*",
    callback = function( opts )
        M.trim( opts.buf )
    end
} )
