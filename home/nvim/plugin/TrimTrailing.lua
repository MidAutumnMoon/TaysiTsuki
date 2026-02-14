local ok, lore = pcall(require, "lore")
local ExcludedFiletypes = ok and lore.ExcludedFiletypes or {}

local config = {
	IgnoredFiles = {},
	debounce_ms = 100,
}

local M = {}
local timers = {}

local function should_trim(buf)
	if not vim.api.nvim_buf_is_valid(buf) then return false end
	local bo = vim.bo[buf]
	if not bo.modifiable then return false end

	local name = vim.fs.basename(vim.api.nvim_buf_get_name(buf)) or ""
	return not (
		vim.tbl_contains(ExcludedFiletypes, bo.ft) or
		vim.tbl_contains(config.IgnoredFiles, name)
	)
end

local function cancel_timer(buf)
	if timers[buf] then
		timers[buf]:close()
		timers[buf] = nil
	end
end

function M.trim(buf)
	if not should_trim(buf) then return end

	local ok_view, saved_view = pcall(vim.fn.winsaveview)
	if not ok_view then return end

	vim.cmd([[keepjumps keeppatterns silent! %s/\s\+$//e]])

	if vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.fn.winrestview, saved_view)
	end
end

function M.schedule_trim(buf)
	cancel_timer(buf)
	if not vim.api.nvim_buf_is_valid(buf) then return end

	timers[buf] = vim.defer_fn(function()
		timers[buf] = nil
		M.trim(buf)
	end, config.debounce_ms)
end

vim.keymap.set("n", "<LocalLeader>\\", function() M.trim(0) end)

local augroup = vim.api.nvim_create_augroup("TrimTrailing", { clear = true })

vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
	group = augroup,
	pattern = "*",
	callback = function(opts) M.schedule_trim(opts.buf) end,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
	group = augroup,
	pattern = "*",
	callback = function(opts) cancel_timer(opts.buf) end,
})

-- ExitPre excluded because buffer may be invalid/unloaded during quit
