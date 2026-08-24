local prompt = require("review_explain.prompt")
local client = require("review_explain.client")
local parser = require("review_explain.parser")
local resolve = require("review_explain.resolve")
local cache = require("review_explain.cache")

local M = {}

M.config = {
	model = nil,
	cache_dirname = ".nvim-review",
}

local ns = vim.api.nvim_create_namespace("review_explain")

---Explain every top-level function in the given (0-indexed, inclusive) range.
---@param bufnr integer
---@param start_lnum integer
---@param end_lnum integer
function M.run(bufnr, start_lnum, end_lnum)
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		vim.notify("review-explain: buffer has no file path", vim.log.levels.ERROR)
		return
	end
	local filetype = vim.bo[bufnr].filetype
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_lnum, end_lnum + 1, false)
	local code = table.concat(lines, "\n")

	vim.notify("review-explain: asking Claude...", vim.log.levels.INFO)

	client.run({
		system_prompt = prompt.SYSTEM_PROMPT,
		user_message = prompt.build_user_message(code, filepath, filetype),
		model = M.config.model,
	}, function(ok, stdout_or_err)
		if not ok then
			vim.notify("review-explain: " .. stdout_or_err, vim.log.levels.ERROR)
			return
		end

		local entries, err = parser.parse_cli_output(stdout_or_err)
		if not entries then
			vim.notify("review-explain: " .. err, vim.log.levels.ERROR)
			return
		end
		if #entries == 0 then
			vim.notify("review-explain: no functions found in selection", vim.log.levels.WARN)
			return
		end

		local body_hashes = {}
		for _, entry in ipairs(entries) do
			-- entry.start_line is 1-indexed relative to the selection; translate
			-- to an absolute 0-indexed buffer line to search from.
			local abs_lnum = start_lnum + entry.start_line - 1
			local found = resolve.find_enclosing_function(bufnr, abs_lnum)
			if found and found.name == entry.name then
				body_hashes[entry.name] = resolve.hash_node(bufnr, found.node)
				vim.api.nvim_buf_set_extmark(bufnr, ns, found.start_line - 1, 0, {
					end_row = found.end_line - 1,
				})
			end
		end

		local cwd = vim.fn.getcwd()
		local cache_path = cache.cache_path(cwd .. "/" .. M.config.cache_dirname, filepath, cwd)
		cache.merge(cache_path, entries, body_hashes)

		vim.notify(string.format("review-explain: explained %d function(s)", #entries), vim.log.levels.INFO)
	end)
end

return M
