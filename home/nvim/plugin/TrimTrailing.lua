local ok, lore = pcall(require, "lore")
local ExcludedFiletypes = ok and lore.ExcludedFiletypes or {}

local config = {
	IgnoredFiles = {}
}

local M = {}

--- Check if buffer is valid and safe to operate on
--- @param buf number
--- @return boolean
local function is_valid_buffer(buf)
	return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modifiable
end

--- @param buf number
function M.validate_buffer(buf)
	if not is_valid_buffer(buf) then
		return false
	end

	local bo = vim.bo[buf]
	local name = vim.fs.basename(vim.api.nvim_buf_get_name(buf)) or ""

	return (
		not vim.tbl_contains(ExcludedFiletypes, bo.ft)
		and not vim.tbl_contains(config.IgnoredFiles, name)
	)
end

--- @param buf integer
function M.trim(buf)
	if not M.validate_buffer(buf) then
		return
	end

	local ok_view, saved_view = pcall(vim.fn.winsaveview)
	if not ok_view then
		return
	end

	vim.cmd([[
        keepjumps keeppatterns silent! %s/\s\+$//e
    ]])

	-- Only restore view if buffer is still valid
	if vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.fn.winrestview, saved_view)
	end
end

vim.keymap.set("n", "<LocalLeader>\\", function()
	M.trim(0)
end)

local augroup = vim.api.nvim_create_augroup("TrimTrailing", { clear = true })

vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
	group = augroup,
	pattern = "*",
	callback = function(opts)
		M.trim(opts.buf)
	end,
})

-- ExitPre excluded because buffer may be invalid/unloaded during quit
