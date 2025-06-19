-- Automatically switch cwd to the root of project.
--
-- Note: not using vim.fs.root() because this implementation
-- is theorically more performant.

local M = {}

M.markers = {

    "README",
    "README.md",

    ".git",

    "flake.nix",
    "shell.nix",
    "default.nix",

    "Cargo.toml",

    -- Manually mark the root
    ".root",

}

M.config = {
    --- How many entries fs_opendir will read.
    OpendirEntries = 2048,
    CdMethod = "tcd",
    ExcludedFiletypes = require "lore".ExcludedFiletypes,
}

function M.validate_buffer( bufnr )
    local bo = vim.bo[bufnr]
    return (
        bo.buftype == "" -- normal buffers
        and ( not vim.tbl_contains( M.config.ExcludedFiletypes, bo.ft ) )
    )
end

--- Check if `folder` contains one of the RootMarkers.
---
--- Notice: only names are checked, meaning no difference bewteen
--- files and dirs.
---
--- @param dir string
--- @return boolean
function M.look_for_marker( dir )
    local entries =
        vim.uv.fs_opendir( dir, nil, M.config.OpendirEntries )
        :readdir()
    return vim.iter( entries or {} )
        :any( function( et )
            return vim.tbl_contains( M.markers, et.name )
        end )
end

function M.callback( opts )
    if not M.validate_buffer( opts.buf ) then
        return false
    end

    local path = vim.api.nvim_buf_get_name( opts.buf )

    local marker_dir = vim.iter( vim.fs.parents( path ) )
        :find( M.look_for_marker )

    if marker_dir then
        vim.cmd[M.config.CdMethod]( marker_dir )
    end
end

vim.api.nvim_create_autocmd( "BufEnter", { callback = M.callback } )

vim.o.autochdir = false
