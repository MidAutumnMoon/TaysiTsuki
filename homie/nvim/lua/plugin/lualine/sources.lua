local M = {}

M.gitsigns = function()
    local gitsigns = vim.b.gitsigns_status_dict
    if gitsigns ~= nil then
        return {
            added = gitsigns.added,
            removed = gitsigns.removed,
            modified = gitsigns.changed
        }
    end
end

return M
