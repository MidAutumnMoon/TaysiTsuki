local M = {}

M.related_to_cwd = function()
    -- /project
    local cwd = vim.fn.getcwd()

    -- buf path /project/src/main.some
    -- -> dirname /project/src
    local file_dir =
        vim.fs.dirname( vim.api.nvim_buf_get_name( 0 ) )

    -- after gsub ./src
    -- append with '/' -> ./src/
    local relative = file_dir:gsub( cwd, '.' ) .. '/'

    return relative
end

vim.keymap.set( "n", "<Leader>e",
    function()
        local cmd = ":edit" .. " " .. M.related_to_cwd()
        vim.api.nvim_feedkeys( cmd, "n", false )
    end,
    {
        silent = true
    }
)
