local M = {}

---@type table<string, boolean>
local FUNCTION_NODE_TYPES = {
	function_declaration = true,
	function_definition = true,
	method_definition = true,
	local_function = true,
	arrow_function = true,
}

---@type table<string, boolean>
local NAME_NODE_TYPES = {
	identifier = true,
	name = true,
	property_identifier = true,
}

---@param bufnr integer
---@param node userdata
---@return string|nil
local function node_name(bufnr, node)
	for child in node:iter_children() do
		if NAME_NODE_TYPES[child:type()] then
			return vim.treesitter.get_node_text(child, bufnr)
		end
	end
	return nil
end

---Find the smallest function-like treesitter node containing `lnum`.
---@param bufnr integer
---@param lnum integer 0-indexed line number
---@return {name:string, start_line:integer, end_line:integer, node:userdata}|nil
function M.find_enclosing_function(bufnr, lnum)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return nil
	end
	local tree = parser:parse()[1]
	if not tree then
		return nil
	end
	local root = tree:root()

	local node = root:named_descendant_for_range(lnum, 0, lnum, 0)
	while node do
		if FUNCTION_NODE_TYPES[node:type()] then
			local name = node_name(bufnr, node)
			if name then
				local srow, _, erow, _ = node:range()
				return { name = name, start_line = srow + 1, end_line = erow + 1, node = node }
			end
		end
		node = node:parent()
	end
	return nil
end

---@param bufnr integer
---@param node userdata
---@return string sha256 hex digest of the node's source text
function M.hash_node(bufnr, node)
	local text = vim.treesitter.get_node_text(node, bufnr)
	return vim.fn.sha256(text)
end

return M
