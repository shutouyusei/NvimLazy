local resolve = require("review_explain.resolve")

local function make_lua_buffer(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = "lua"
  return bufnr
end

describe("review_explain.resolve.find_enclosing_function", function()
  it("finds a local function containing the given line", function()
    local bufnr = make_lua_buffer({
      "local function calculate_reward(x)",
      "  local y = x * 2",
      "  return y",
      "end",
    })
    local found = resolve.find_enclosing_function(bufnr, 1) -- inside the body
    assert.is_table(found)
    assert.equal("calculate_reward", found.name)
    assert.equal(1, found.start_line)
    assert.equal(4, found.end_line)
  end)

  it("returns nil when the line is outside any function", function()
    local bufnr = make_lua_buffer({
      "local x = 1",
      "local y = 2",
    })
    assert.is_nil(resolve.find_enclosing_function(bufnr, 0))
  end)
end)

describe("review_explain.resolve.hash_node", function()
  it("produces the same hash for identical function bodies", function()
    local buf_a = make_lua_buffer({ "local function f()", "  return 1", "end" })
    local buf_b = make_lua_buffer({ "local function f()", "  return 1", "end" })
    local node_a = resolve.find_enclosing_function(buf_a, 1).node
    local node_b = resolve.find_enclosing_function(buf_b, 1).node
    assert.equal(resolve.hash_node(buf_a, node_a), resolve.hash_node(buf_b, node_b))
  end)

  it("produces a different hash when the body changes", function()
    local buf_a = make_lua_buffer({ "local function f()", "  return 1", "end" })
    local buf_b = make_lua_buffer({ "local function f()", "  return 2", "end" })
    local node_a = resolve.find_enclosing_function(buf_a, 1).node
    local node_b = resolve.find_enclosing_function(buf_b, 1).node
    assert.is_not.equal(resolve.hash_node(buf_a, node_a), resolve.hash_node(buf_b, node_b))
  end)
end)
