local resolve = require("review_explain.resolve")
local cache = require("review_explain.cache")
local display = require("review_explain.display")
local generate = require("review_explain.generate")

local M = {}

---Look up the cached explanation for the function under the cursor, if any.
---@param bufnr integer
---@return string|nil explanation
local function find_cached_explanation(bufnr)
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local found = resolve.find_enclosing_function(bufnr, lnum)
	if not found then
		return nil
	end

	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		return nil
	end
	local root = cache.resolve_root(bufnr)
	local cache_path = cache.cache_path(root .. "/" .. generate.config.cache_dirname, filepath, root)
	local entries = cache.read(cache_path)
	local revisions = entries[found.name]
	if not revisions then
		return nil
	end

	local current_hash = resolve.hash_node(bufnr, found.node)
	for _, revision in ipairs(revisions) do
		if revision.body_hash == current_hash then
			return revision.explanation
		end
	end
	return nil
end

---Request LSP hover for the cursor position and return its markdown lines.
---Calls back with an empty table if there's no LSP client or no hover info.
---@param bufnr integer
---@param callback fun(lines: string[])
local function request_hover(bufnr, callback)
	local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" })
	if #clients == 0 then
		callback({})
		return
	end
	local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding)
	vim.lsp.buf_request_all(bufnr, "textDocument/hover", params, function(results)
		local lines = {}
		for _, resp in pairs(results) do
			local result = resp.result
			if result and result.contents then
				vim.list_extend(lines, vim.lsp.util.convert_input_to_markdown_lines(result.contents))
			end
		end
		callback(lines)
	end)
end

---Show LSP hover and any cached explanation for the function under the
---cursor together in one floating window, instead of one replacing the
---other.
---@param bufnr integer
function M.show(bufnr)
	local explanation = find_cached_explanation(bufnr)

	request_hover(bufnr, function(hover_lines)
		local lines = {}
		vim.list_extend(lines, hover_lines)

		if explanation then
			if #lines > 0 then
				table.insert(lines, "---")
			end
			table.insert(lines, "**AI explanation:**")
			vim.list_extend(lines, vim.split(explanation, "\n"))
		end

		if #lines == 0 then
			vim.notify("No information available", vim.log.levels.INFO)
			return
		end

		display.show(lines)
	end)
end

return M
