local resolve = require("review_explain.resolve")
local cache = require("review_explain.cache")
local display = require("review_explain.display")
local generate = require("review_explain.generate")

local M = {}

---Show the cached explanation for the function under the cursor, if any.
---@param bufnr integer
---@return boolean shown true if a cached explanation was displayed
function M.show(bufnr)
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local found = resolve.find_enclosing_function(bufnr, lnum)
	if not found then
		return false
	end

	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		return false
	end
	local cwd = vim.fn.getcwd()
	local cache_path = cache.cache_path(cwd .. "/" .. generate.config.cache_dirname, filepath, cwd)
	local entries = cache.read(cache_path)
	local entry = entries[found.name]
	if not entry then
		return false
	end

	local current_hash = resolve.hash_node(bufnr, found.node)
	if entry.body_hash ~= current_hash then
		return false
	end

	display.show(vim.split(entry.explanation, "\n"))
	return true
end

return M
