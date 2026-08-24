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
---@return table entries keyed by function name -> list of revisions (most recent first); empty table if absent/empty
---@return boolean decode_failed true if the file exists with content but could not be decoded as JSON
function M.read(path)
	local f = io.open(path, "r")
	if not f then
		return {}, false
	end
	local content = f:read("*a")
	f:close()
	if content == "" then
		return {}, false
	end
	local ok, decoded = pcall(vim.json.decode, content)
	if not ok or type(decoded) ~= "table" then
		return {}, true
	end
	return decoded, false
end

---@param t table
---@return boolean
local function is_array(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n == #t
end

---Serialize a value as pretty-printed, deterministically-ordered JSON.
---Object keys are sorted alphabetically; indentation uses tabs. This keeps
---regenerated cache files reviewable as git diffs (unlike vim.json.encode's
---single-line, insertion-order output).
---@param value any
---@param indent string
---@return string
local function encode_value(value, indent)
	local t = type(value)
	if t == "string" or t == "number" or t == "boolean" then
		return vim.json.encode(value)
	elseif t == "nil" then
		return "null"
	elseif t == "table" then
		if vim.tbl_isempty(value) then
			return "{}"
		end
		local child_indent = indent .. "\t"
		if is_array(value) then
			local items = {}
			for _, v in ipairs(value) do
				table.insert(items, child_indent .. encode_value(v, child_indent))
			end
			return "[\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "]"
		else
			local keys = vim.tbl_keys(value)
			table.sort(keys)
			local items = {}
			for _, k in ipairs(keys) do
				table.insert(items, child_indent .. vim.json.encode(k) .. ": " .. encode_value(value[k], child_indent))
			end
			return "{\n" .. table.concat(items, ",\n") .. "\n" .. indent .. "}"
		end
	end
	error("review-explain: cannot encode value of type " .. t)
end

---@param entries table
---@return string
local function encode_sorted(entries)
	return encode_value(entries, "")
end

---@param path string
---@param entries table
---@param opts table|nil {backup_corrupt: boolean} when true, back up any existing
---  file at `path` to `path .. ".bak"` before overwriting (used when the
---  previous `read()` of this path failed to decode, so we never silently
---  destroy unrecoverable content).
function M.write(path, entries, opts)
	opts = opts or {}
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

	if opts.backup_corrupt then
		local existing_f = io.open(path, "r")
		if existing_f then
			local content = existing_f:read("*a")
			existing_f:close()
			local bak = assert(io.open(path .. ".bak", "w"))
			bak:write(content)
			bak:close()
		end
	end

	-- Write to a temp file in the same directory, then rename over the real
	-- path (atomic on POSIX), so a crash mid-write can't corrupt the cache.
	local tmp_path = path .. ".tmp"
	local f = assert(io.open(tmp_path, "w"))
	f:write(encode_sorted(entries))
	f:close()
	local ok, err = os.rename(tmp_path, path)
	if not ok then
		error("review-explain: failed to write cache file " .. path .. ": " .. tostring(err))
	end
end

---Merge new explanation entries into the cache at `path`, keyed by name.
---Each name maps to a list of revisions (most recent first), so the same
---function name can carry distinct entries for distinct body hashes (e.g.
---old vs. new content across commits, for diffview.nvim compatibility).
---@param path string
---@param new_entries table[] parser entries: {name, start_line, end_line, explanation}
---@param body_hashes table<string, string> name -> body_hash
---@return table the full merged cache table
function M.merge(path, new_entries, body_hashes)
	local existing, decode_failed = M.read(path)
	if decode_failed then
		vim.notify(
			"review-explain: cache file could not be decoded, backing up to "
				.. path
				.. ".bak and starting fresh: "
				.. path,
			vim.log.levels.WARN
		)
	end

	local now = os.date("!%Y-%m-%dT%H:%M:%SZ")
	for _, entry in ipairs(new_entries) do
		local hash = body_hashes[entry.name]
		local revisions = existing[entry.name] or {}

		local matched = false
		for _, revision in ipairs(revisions) do
			if revision.body_hash == hash then
				revision.start_line = entry.start_line
				revision.end_line = entry.end_line
				revision.explanation = entry.explanation
				revision.generated_at = now
				matched = true
				break
			end
		end

		if not matched then
			table.insert(revisions, 1, {
				start_line = entry.start_line,
				end_line = entry.end_line,
				body_hash = hash,
				explanation = entry.explanation,
				generated_at = now,
			})
		end

		existing[entry.name] = revisions
	end

	M.write(path, existing, { backup_corrupt = decode_failed })
	return existing
end

return M
