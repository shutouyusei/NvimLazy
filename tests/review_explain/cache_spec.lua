local cache = require("review_explain.cache")

local function tmp_dir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return dir
end

describe("review_explain.cache.cache_path", function()
  it("mirrors the file's path relative to cwd, under the cache root, with .json appended", function()
    local path = cache.cache_path("/proj/.nvim-review", "/proj/src/foo.lua", "/proj")
    assert.equal("/proj/.nvim-review/src/foo.lua.json", path)
  end)
end)

describe("review_explain.cache read/write/merge", function()
  it("read returns an empty table when the file does not exist", function()
    local dir = tmp_dir()
    assert.same({}, cache.read(dir .. "/nope.json"))
  end)

  it("write then read round-trips the data", function()
    local dir = tmp_dir()
    local path = dir .. "/sub/foo.lua.json"
    cache.write(path, { foo = { explanation = "does a thing" } })
    local got = cache.read(path)
    assert.equal("does a thing", got.foo.explanation)
  end)

  it("merge adds new entries with body_hash and generated_at, keyed by name", function()
    local dir = tmp_dir()
    local path = dir .. "/foo.lua.json"
    local entries = {
      { name = "foo", start_line = 1, end_line = 3, explanation = "does a thing" },
    }
    local result = cache.merge(path, entries, { foo = "abc123" })
    assert.equal(1, result.foo.start_line)
    assert.equal(3, result.foo.end_line)
    assert.equal("abc123", result.foo.body_hash)
    assert.equal("does a thing", result.foo.explanation)
    assert.is_string(result.foo.generated_at)
  end)

  it("merge preserves existing entries not touched by this call", function()
    local dir = tmp_dir()
    local path = dir .. "/foo.lua.json"
    cache.write(path, { bar = { explanation = "old" } })
    cache.merge(path, {
      { name = "foo", start_line = 1, end_line = 2, explanation = "new" },
    }, { foo = "h" })
    local got = cache.read(path)
    assert.equal("old", got.bar.explanation)
    assert.equal("new", got.foo.explanation)
  end)
end)
