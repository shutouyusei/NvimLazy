local M = {}

---Compute the cache file path for a source file.
---@param cache_root string absolute path to the `.nvim-review` directory
---@param filepath string absolute path to the source file
---@param cwd string absolute path of the project root
---@return string
function M.cache_path(cache_root, filepath, cwd)
	local rel = filepath
	if vim.startswith(filepath, cwd .. "/") then
		rel = filepath:sub(#cwd + 2)
	end
	return cache_root .. "/" .. rel .. ".json"
end

---@param path string
---@return table entries keyed by function name; empty table if absent/unreadable
function M.read(path)
	local f = io.open(path, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()
	if content == "" then
		return {}
	end
	local ok, decoded = pcall(vim.json.decode, content)
	if not ok or type(decoded) ~= "table" then
		return {}
	end
	return decoded
end

---@param path string
---@param entries table
function M.write(path, entries)
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	local f = assert(io.open(path, "w"))
	f:write(vim.json.encode(entries))
	f:close()
end

---Merge new explanation entries into the cache at `path`, keyed by name.
---@param path string
---@param new_entries table[] parser entries: {name, start_line, end_line, explanation}
---@param body_hashes table<string, string> name -> body_hash
---@return table the full merged cache table
function M.merge(path, new_entries, body_hashes)
	local existing = M.read(path)
	local now = os.date("!%Y-%m-%dT%H:%M:%SZ")
	for _, entry in ipairs(new_entries) do
		existing[entry.name] = {
			start_line = entry.start_line,
			end_line = entry.end_line,
			body_hash = body_hashes[entry.name],
			explanation = entry.explanation,
			generated_at = now,
		}
	end
	M.write(path, existing)
	return existing
end

return M
