vim.o.autowriteall = true

local M = {}

--- @param buf number
--- @return boolean
function M.validate_buffer( buf )
    local bo = vim.bo[buf]
    return (
        bo.modified
        and not bo.readonly
        and bo.modifiable
        and vim.api.nvim_buf_get_name( buf ) ~= ""
    )
end

function M.callback( opt )
    local buf = opt.buf
    if not M.validate_buffer( buf ) then
        return
    end
    vim.api.nvim_buf_call( buf, function()
        vim.cmd.bufdo {
            "write",
            range = { buf },
            mods = { silent = true }
        }
        vim.cmd.doautocmd {
            "BufWritePost",
            mods = { silent = true }
        }
    end )
end

vim.api.nvim_create_autocmd ( {
    "InsertLeave",
    "TextChanged",
    "BufEnter",
    "BufLeave",
}, {
    pattern = "*",
    callback = M.callback,
} )

