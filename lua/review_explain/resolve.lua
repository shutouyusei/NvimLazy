local M = {}

---@type table<string, boolean>
local FUNCTION_NODE_TYPES = {
	function_declaration = true,
	function_definition = true,
}

---@type table<string, boolean>
local NAME_NODE_TYPES = {
	identifier = true,
	name = true,
	property_identifier = true,
}

---Extract the rightmost identifier from a dot_index_expression or method_index_expression.
---@param bufnr integer
---@param expr_node userdata
---@return string|nil
local function extract_index_name(bufnr, expr_node)
	-- For dot_index_expression (M.foo) or method_index_expression (M:method),
	-- iterate to find the rightmost identifier
	local rightmost_id = nil
	for child in expr_node:iter_children() do
		if child:type() == "identifier" or child:type() == "property_identifier" then
			rightmost_id = vim.treesitter.get_node_text(child, bufnr)
		end
	end
	return rightmost_id
end

---Extract the function name from an assignment LHS (e.g., M.foo in "M.foo = function() end").
---@param bufnr integer
---@param assign_node userdata
---@return string|nil
local function extract_assignment_name(bufnr, assign_node)
	-- The assignment statement has children: (variable_list, "=", expression_list)
	-- The variable_list contains the LHS; we want the rightmost identifier in it
	local var_list = nil
	for child in assign_node:iter_children() do
		if child:type() == "variable_list" then
			var_list = child
			break
		end
	end

	if not var_list then
		return nil
	end

	-- Within the variable_list, look for a field (dot_index_expression, method_index_expression, identifier, etc.)
	local rightmost_id = nil
	for child in var_list:iter_children() do
		if child:type() == "dot_index_expression" or child:type() == "method_index_expression" then
			-- Extract the rightmost identifier from the index expression
			rightmost_id = extract_index_name(bufnr, child)
		elseif child:type() == "identifier" or child:type() == "property_identifier" then
			rightmost_id = vim.treesitter.get_node_text(child, bufnr)
		end
	end
	return rightmost_id
end

---Resolve the name of a function-like treesitter node.
---Handles: local function foo(), function M.foo(), function M:method(), and M.foo = function().
---@param bufnr integer
---@param node userdata (must be a function node type)
---@return string|nil
local function node_name(bufnr, node)
	-- Try direct children first (for simple cases like "local function foo()" where the first
	-- identifier child is the name)
	for child in node:iter_children() do
		if NAME_NODE_TYPES[child:type()] then
			return vim.treesitter.get_node_text(child, bufnr)
		end
	end

	-- Try to find a dot_index_expression or method_index_expression child (for "function M.foo()" or "function M:method()")
	for child in node:iter_children() do
		if child:type() == "dot_index_expression" or child:type() == "method_index_expression" then
			return extract_index_name(bufnr, child)
		end
	end

	-- If the function node has no name-bearing child, check if an ancestor is an assignment_statement
	-- (for "M.foo = function()" style). The function_definition is inside expression_list which is
	-- inside assignment_statement.
	local parent = node:parent()
	while parent do
		if parent:type() == "assignment_statement" then
			return extract_assignment_name(bufnr, parent)
		end
		parent = parent:parent()
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
