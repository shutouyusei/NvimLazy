local resolve = require("review_explain.resolve")
local cache = require("review_explain.cache")
local display = require("review_explain.display")
local config = require("review_explain.config")

local M = {}

local highlight_ns = vim.api.nvim_create_namespace("review_explain_highlight")

---@param bufnr integer
---@return string cache_path
local function cache_path_for_buffer(bufnr)
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local root = cache.resolve_root(bufnr)
	return cache.cache_path(root .. "/" .. config.cache_dirname, filepath, root)
end

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
	local entries = cache.read(cache_path_for_buffer(bufnr))
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

---Highlight every function in the buffer that has a cached explanation
---matching its current content (body_hash), so explained functions are
---visible at a glance without pressing K on each one.
---@param bufnr integer
function M.highlight_buffer(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, highlight_ns, 0, -1)

	if vim.api.nvim_buf_get_name(bufnr) == "" then
		return
	end

	local entries = cache.read(cache_path_for_buffer(bufnr))
	if vim.tbl_isempty(entries) then
		return
	end

	for _, fn in ipairs(resolve.find_all_functions(bufnr)) do
		local revisions = entries[fn.name]
		if revisions then
			local current_hash = resolve.hash_node(bufnr, fn.node)
			for _, revision in ipairs(revisions) do
				if revision.body_hash == current_hash then
					-- A sign-column marker rather than a background highlight:
					-- background-based highlighting is invisible under a
					-- transparent-background colorscheme (many "linkable"
					-- groups like Folded carry no bg in that case), while a
					-- colored sign glyph is unaffected by that.
					for row = fn.start_line - 1, fn.end_line - 1 do
						vim.api.nvim_buf_set_extmark(bufnr, highlight_ns, row, 0, {
							sign_text = "▎",
							sign_hl_group = "ReviewExplainExplained",
						})
					end
					break
				end
			end
		end
	end
end

return M
