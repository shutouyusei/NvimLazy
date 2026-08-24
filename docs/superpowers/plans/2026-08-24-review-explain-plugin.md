# review-explain.nvim Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the MVP described in the spec — select a code range, get a per-function AI explanation from Claude, cache it durably, and recall it instantly by placing the cursor in an already-explained function.

**Architecture:** A small, dependency-injectable Lua module tree under `lua/review_explain/`, wired into the existing lazy.nvim config via one new `lua/plugins/review-explain.lua` spec file. Pure logic (prompt building, response parsing, cache read/write, treesitter resolution) is unit-tested with `plenary.nvim`'s busted-style test harness (already a dependency in this config). The only non-pure boundary — spawning the real `claude` CLI — is isolated in `client.lua` behind an injectable `runner` function so the orchestration logic (`generate.lua`) stays testable without ever invoking the real subprocess in CI/test runs.

**Tech Stack:** Neovim Lua (`vim.treesitter`, `vim.system`, `vim.json`, `vim.lsp.util.open_floating_preview`), `plenary.nvim` (test harness, already installed), the `claude` CLI's `-p`/`--output-format json` non-interactive mode (no other AI SDK/library).

**Spec:** `docs/superpowers/specs/2026-08-24-review-explain-plugin-design.md`

## Global Constraints

- All AI calls go through the real `claude` CLI binary in print mode (`claude -p ... --output-format json`) — never the Agent SDK, never ACP, never a raw API key. This is the authentication/ToS constraint from the spec and is non-negotiable.
- Cached explanations live in `.nvim-review/<relative-file-path>.json`, git-tracked (not gitignored).
- Stored `start_line`/`end_line` in the cache are hints only. The name + `body_hash` pair is the source of truth; every read re-resolves position via treesitter against the live buffer.
- No feature in this plan may trigger a `claude -p` call automatically (on hover, on save, on timer). Only the explicit generate action costs an AI call.
- Lua files stay under ~200 lines each (this user's `coding-style.md` "Small File Principle"); one clear responsibility per file.
- Every public function gets a `---@param`/`---@return` LuaCATS annotation (matches the `.luarc.json` already present in this config).

---

## File Structure

```
lua/review_explain/
  prompt.lua     -- builds the system prompt and per-call user message (pure)
  parser.lua     -- parses claude -p's JSON envelope + the fenced explanation JSON (pure)
  cache.lua      -- reads/writes .nvim-review/<relpath>.json (file I/O, no network)
  resolve.lua    -- treesitter: find enclosing function, compute body hash (buffer I/O, no network)
  client.lua     -- builds argv for `claude -p`, runs it via injectable runner (async)
  display.lua    -- floating-window rendering (thin wrapper over vim.lsp.util.open_floating_preview)
  generate.lua   -- orchestrates: selection -> prompt -> client -> parser -> resolve -> cache -> extmark
  recall.lua     -- orchestrates: cursor -> resolve -> cache -> display
lua/plugins/
  review-explain.lua -- lazy.nvim spec: keys, K override with fallback, dependencies
tests/
  minimal_init.lua
  review_explain/
    prompt_spec.lua
    parser_spec.lua
    cache_spec.lua
    resolve_spec.lua
    client_spec.lua
```

Each task below creates or modifies exactly the files it lists. Later tasks only ever `require` earlier tasks' modules by the exact names/signatures given here — no task needs to guess a neighboring module's shape.

---

### Task 1: Test harness + prompt module

**Files:**
- Create: `tests/minimal_init.lua`
- Create: `lua/review_explain/prompt.lua`
- Test: `tests/review_explain/prompt_spec.lua`

**Interfaces:**
- Produces: `review_explain.prompt.SYSTEM_PROMPT` (string constant), `review_explain.prompt.build_user_message(code, filepath, filetype) -> string`

- [ ] **Step 1: Create the plenary test harness bootstrap**

`tests/minimal_init.lua`:

```lua
local plenary_dir = vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim")
local nvim_treesitter_dir = vim.fn.expand("~/.local/share/nvim/lazy/nvim-treesitter")
local config_dir = vim.fn.getcwd()

vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(nvim_treesitter_dir)
vim.opt.rtp:append(config_dir)

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
```

- [ ] **Step 2: Write the failing test for the user message builder**

`tests/review_explain/prompt_spec.lua`:

```lua
local prompt = require("review_explain.prompt")

describe("review_explain.prompt", function()
  it("embeds the file path, language, and code in the user message", function()
    local msg = prompt.build_user_message("local x = 1", "/tmp/foo.lua", "lua")
    assert.truthy(msg:find("/tmp/foo.lua", 1, true))
    assert.truthy(msg:find("lua", 1, true))
    assert.truthy(msg:find("local x = 1", 1, true))
  end)

  it("exposes a non-empty system prompt that demands fenced JSON output", function()
    assert.is_string(prompt.SYSTEM_PROMPT)
    assert.truthy(prompt.SYSTEM_PROMPT:find("JSON", 1, true))
    assert.truthy(prompt.SYSTEM_PROMPT:find("start_line", 1, true))
  end)
end)
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/prompt_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: FAIL — `module 'review_explain.prompt' not found`

- [ ] **Step 4: Implement the prompt module**

`lua/review_explain/prompt.lua`:

```lua
local M = {}

---@type string
M.SYSTEM_PROMPT = [[
You are a code explanation assistant embedded in a Neovim plugin.
You will be given a snippet of source code from a file.
Identify each top-level function or method defined in the snippet.
For each one, produce a concise explanation (2-4 sentences, no code
repetition) of what it does.

Respond with ONLY a single fenced code block containing a JSON array,
and nothing else before or after it. Each element must have this exact
shape:

{"name": string, "start_line": integer, "end_line": integer, "explanation": string}

start_line and end_line are 1-indexed line numbers relative to the
snippet you were given (the first line of the snippet is line 1).
If the snippet contains no top-level function/method, return an empty
JSON array: []
]]

---Build the per-call user message sent to `claude -p`.
---@param code string the selected source code
---@param filepath string absolute or relative path of the source file
---@param filetype string neovim filetype, used as the fence language
---@return string
function M.build_user_message(code, filepath, filetype)
  return string.format("File: %s\nLanguage: %s\n\n```%s\n%s\n```", filepath, filetype, filetype, code)
end

return M
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/prompt_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: PASS (2 successes)

- [ ] **Step 6: Commit**

```bash
cd ~/.config/nvim
git add tests/minimal_init.lua lua/review_explain/prompt.lua tests/review_explain/prompt_spec.lua
git commit -m "review-explain: add test harness and prompt module"
```

---

### Task 2: Response parser

**Files:**
- Create: `lua/review_explain/parser.lua`
- Test: `tests/review_explain/parser_spec.lua`

**Interfaces:**
- Consumes: nothing from other review_explain modules
- Produces: `review_explain.parser.extract_fenced_block(text) -> string|nil`, `review_explain.parser.parse_cli_output(stdout) -> entries|nil, err|nil` where `entries` is `{ {name=string, start_line=number, end_line=number, explanation=string}, ... }`

- [ ] **Step 1: Write the failing tests**

`tests/review_explain/parser_spec.lua`:

```lua
local parser = require("review_explain.parser")

describe("review_explain.parser.extract_fenced_block", function()
  it("returns the contents between the first fence pair", function()
    local text = "here you go:\n```json\n[1,2,3]\n```\nhope that helps"
    assert.equal("[1,2,3]", parser.extract_fenced_block(text))
  end)

  it("returns nil when there is no fence", function()
    assert.is_nil(parser.extract_fenced_block("no fences here"))
  end)
end)

describe("review_explain.parser.parse_cli_output", function()
  it("parses a well-formed envelope with a fenced JSON array", function()
    local envelope = vim.json.encode({
      is_error = false,
      result = '```json\n[{"name":"foo","start_line":1,"end_line":3,"explanation":"does a thing"}]\n```',
    })
    local entries, err = parser.parse_cli_output(envelope)
    assert.is_nil(err)
    assert.equal(1, #entries)
    assert.equal("foo", entries[1].name)
    assert.equal(1, entries[1].start_line)
    assert.equal(3, entries[1].end_line)
    assert.equal("does a thing", entries[1].explanation)
  end)

  it("also accepts an unfenced JSON array in result", function()
    local envelope = vim.json.encode({
      is_error = false,
      result = '[{"name":"foo","start_line":1,"end_line":2,"explanation":"x"}]',
    })
    local entries, err = parser.parse_cli_output(envelope)
    assert.is_nil(err)
    assert.equal(1, #entries)
  end)

  it("returns an error when the top-level JSON is invalid", function()
    local entries, err = parser.parse_cli_output("not json at all")
    assert.is_nil(entries)
    assert.is_string(err)
  end)

  it("returns an error when is_error is true", function()
    local envelope = vim.json.encode({ is_error = true, result = "boom" })
    local entries, err = parser.parse_cli_output(envelope)
    assert.is_nil(entries)
    assert.is_string(err)
  end)

  it("returns an error when an entry is missing a required field", function()
    local envelope = vim.json.encode({
      is_error = false,
      result = '```json\n[{"name":"foo","start_line":1}]\n```',
    })
    local entries, err = parser.parse_cli_output(envelope)
    assert.is_nil(entries)
    assert.is_string(err)
  end)
end)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/parser_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: FAIL — `module 'review_explain.parser' not found`

- [ ] **Step 3: Implement the parser module**

`lua/review_explain/parser.lua`:

```lua
local M = {}

---Extract the contents of the first fenced code block in `text`.
---@param text string
---@return string|nil
function M.extract_fenced_block(text)
  return text:match("```[%w]*\n(.-)\n```")
end

local REQUIRED_FIELDS = { "name", "start_line", "end_line", "explanation" }

---@param entry table
---@return boolean
local function is_valid_entry(entry)
  if type(entry) ~= "table" then
    return false
  end
  for _, field in ipairs(REQUIRED_FIELDS) do
    if entry[field] == nil then
      return false
    end
  end
  return type(entry.name) == "string"
    and type(entry.start_line) == "number"
    and type(entry.end_line) == "number"
    and type(entry.explanation) == "string"
end

---Parse the full stdout of `claude -p ... --output-format json`.
---@param stdout string
---@return table[]|nil entries
---@return string|nil err
function M.parse_cli_output(stdout)
  local ok, envelope = pcall(vim.json.decode, stdout)
  if not ok then
    return nil, "invalid top-level JSON from claude -p: " .. tostring(envelope)
  end
  if envelope.is_error then
    return nil, "claude -p reported is_error=true"
  end
  if type(envelope.result) ~= "string" then
    return nil, "missing string 'result' field in claude -p output"
  end

  local fenced = M.extract_fenced_block(envelope.result)
  local json_text = fenced or envelope.result

  local ok2, entries = pcall(vim.json.decode, json_text)
  if not ok2 then
    return nil, "could not parse explanation JSON: " .. tostring(entries)
  end
  if type(entries) ~= "table" then
    return nil, "explanation JSON was not an array"
  end

  for _, entry in ipairs(entries) do
    if not is_valid_entry(entry) then
      return nil, "an explanation entry was missing a required field"
    end
  end

  return entries, nil
end

return M
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/parser_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: PASS (6 successes)

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add lua/review_explain/parser.lua tests/review_explain/parser_spec.lua
git commit -m "review-explain: add claude -p response parser"
```

---

### Task 3: Cache read/write/merge

**Files:**
- Create: `lua/review_explain/cache.lua`
- Test: `tests/review_explain/cache_spec.lua`

**Interfaces:**
- Consumes: nothing from other review_explain modules
- Produces: `review_explain.cache.cache_path(cache_root, filepath, cwd) -> string`, `review_explain.cache.read(path) -> table`, `review_explain.cache.write(path, entries)`, `review_explain.cache.merge(path, new_entries, body_hashes) -> table` where `new_entries` is the parser's entry list and `body_hashes` is `{ [name] = hash_string }`

- [ ] **Step 1: Write the failing tests**

`tests/review_explain/cache_spec.lua`:

```lua
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/cache_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: FAIL — `module 'review_explain.cache' not found`

- [ ] **Step 3: Implement the cache module**

`lua/review_explain/cache.lua`:

```lua
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/cache_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: PASS (5 successes)

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add lua/review_explain/cache.lua tests/review_explain/cache_spec.lua
git commit -m "review-explain: add cache read/write/merge"
```

---

### Task 4: Treesitter resolution (find function, hash body)

**Files:**
- Create: `lua/review_explain/resolve.lua`
- Test: `tests/review_explain/resolve_spec.lua`

**Interfaces:**
- Consumes: nothing from other review_explain modules
- Produces: `review_explain.resolve.find_enclosing_function(bufnr, lnum) -> {name, start_line, end_line, node}|nil` (lnum is 0-indexed), `review_explain.resolve.hash_node(bufnr, node) -> string`

- [ ] **Step 1: Write the failing tests**

`tests/review_explain/resolve_spec.lua`:

```lua
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/resolve_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: FAIL — `module 'review_explain.resolve' not found`

- [ ] **Step 3: Implement the resolve module**

`lua/review_explain/resolve.lua`:

```lua
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/resolve_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: PASS (4 successes)

If it fails with a treesitter parser-not-found error for `lua`, confirm the parser is installed: `ls ~/.local/share/nvim/lazy/nvim-treesitter/parser/lua.so` (it was installed earlier this session; if missing, run `nvim --headless -c "TSInstallSync lua" -c "qa!"` and retry).

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add lua/review_explain/resolve.lua tests/review_explain/resolve_spec.lua
git commit -m "review-explain: add treesitter function resolution and hashing"
```

---

### Task 5: Claude CLI client (injectable runner)

**Files:**
- Create: `lua/review_explain/client.lua`
- Test: `tests/review_explain/client_spec.lua`

**Interfaces:**
- Consumes: nothing from other review_explain modules
- Produces: `review_explain.client.build_cmd(opts) -> string[]` where `opts = {system_prompt, user_message, model}`; `review_explain.client.run(opts, on_done, runner)` where `on_done = fun(ok: boolean, stdout_or_err: string)` and `runner` defaults to a `vim.system`-based implementation but can be swapped in tests

- [ ] **Step 1: Write the failing tests**

`tests/review_explain/client_spec.lua`:

```lua
local client = require("review_explain.client")

describe("review_explain.client.build_cmd", function()
  it("builds the base claude -p command with print/json flags", function()
    local cmd = client.build_cmd({ system_prompt = "sys", user_message = "hello" })
    assert.same({ "claude", "-p", "hello", "--output-format", "json", "--system-prompt", "sys" }, cmd)
  end)

  it("appends --model when provided", function()
    local cmd = client.build_cmd({ system_prompt = "sys", user_message = "hello", model = "haiku" })
    assert.same(
      { "claude", "-p", "hello", "--output-format", "json", "--system-prompt", "sys", "--model", "haiku" },
      cmd
    )
  end)
end)

describe("review_explain.client.run", function()
  it("calls on_done(true, stdout) when the fake runner exits 0", function()
    local fake_runner = function(_cmd, _run_opts, cb)
      cb({ code = 0, stdout = '{"result":"ok"}', stderr = "" })
    end
    local got_ok, got_out
    client.run({ system_prompt = "s", user_message = "u" }, function(ok, out)
      got_ok, got_out = ok, out
    end, fake_runner)
    vim.wait(100, function() return got_ok ~= nil end)
    assert.is_true(got_ok)
    assert.equal('{"result":"ok"}', got_out)
  end)

  it("calls on_done(false, stderr) when the fake runner exits non-zero", function()
    local fake_runner = function(_cmd, _run_opts, cb)
      cb({ code = 1, stdout = "", stderr = "boom" })
    end
    local got_ok, got_out
    client.run({ system_prompt = "s", user_message = "u" }, function(ok, out)
      got_ok, got_out = ok, out
    end, fake_runner)
    vim.wait(100, function() return got_ok ~= nil end)
    assert.is_false(got_ok)
    assert.equal("boom", got_out)
  end)
end)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/client_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: FAIL — `module 'review_explain.client' not found`

- [ ] **Step 3: Implement the client module**

`lua/review_explain/client.lua`:

```lua
local M = {}

---@class ReviewExplainClientOpts
---@field system_prompt string
---@field user_message string
---@field model string|nil

---Build the argv for a one-shot `claude -p` call.
---@param opts ReviewExplainClientOpts
---@return string[]
function M.build_cmd(opts)
  local cmd = { "claude", "-p", opts.user_message, "--output-format", "json", "--system-prompt", opts.system_prompt }
  if opts.model then
    vim.list_extend(cmd, { "--model", opts.model })
  end
  return cmd
end

---Run `claude -p` asynchronously and report the result.
---@param opts ReviewExplainClientOpts
---@param on_done fun(ok: boolean, stdout_or_err: string)
---@param runner fun(cmd: string[], run_opts: table, cb: fun(obj: table))|nil defaults to vim.system
function M.run(opts, on_done, runner)
  runner = runner or function(cmd, run_opts, cb)
    vim.system(cmd, run_opts, cb)
  end
  local cmd = M.build_cmd(opts)
  runner(cmd, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        on_done(false, (obj.stderr and obj.stderr ~= "") and obj.stderr or ("claude exited with code " .. obj.code))
        return
      end
      on_done(true, obj.stdout)
    end)
  end)
end

return M
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd ~/.config/nvim && nvim --headless -c "PlenaryBustedFile tests/review_explain/client_spec.lua {minimal_init = 'tests/minimal_init.lua'}"`
Expected: PASS (4 successes)

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add lua/review_explain/client.lua tests/review_explain/client_spec.lua
git commit -m "review-explain: add injectable claude -p client"
```

---

### Task 6: Display module (no test — trivial passthrough, verified manually in Task 8)

**Files:**
- Create: `lua/review_explain/display.lua`

**Interfaces:**
- Consumes: nothing from other review_explain modules
- Produces: `review_explain.display.show(lines, opts)` where `lines` is `string[]`

- [ ] **Step 1: Implement the display module**

`lua/review_explain/display.lua`:

```lua
local M = {}

---Show `lines` in a floating window styled like LSP hover.
---@param lines string[]
---@param opts table|nil extra options merged into vim.lsp.util.open_floating_preview's opts
function M.show(lines, opts)
  opts = opts or {}
  vim.lsp.util.open_floating_preview(lines, "markdown", vim.tbl_extend("force", {
    border = "rounded",
    focusable = false,
  }, opts))
end

return M
```

This is a one-line wrapper around a documented Neovim API with no branching logic worth a unit test; it is exercised end-to-end by the manual verification in Task 8.

- [ ] **Step 2: Commit**

```bash
cd ~/.config/nvim
git add lua/review_explain/display.lua
git commit -m "review-explain: add floating-window display wrapper"
```

---

### Task 7: Generate and recall orchestration

**Files:**
- Create: `lua/review_explain/generate.lua`
- Create: `lua/review_explain/recall.lua`

**Interfaces:**
- Consumes: `review_explain.prompt`, `review_explain.client`, `review_explain.parser`, `review_explain.resolve`, `review_explain.cache` (generate.lua); `review_explain.resolve`, `review_explain.cache`, `review_explain.display` (recall.lua)
- Produces: `review_explain.generate.run(bufnr, start_lnum, end_lnum)` (0-indexed, end inclusive), `review_explain.generate.config` (table with `model`, `cache_dirname`); `review_explain.recall.show(bufnr) -> boolean`

No new automated tests here: this task is glue code wiring five already-tested pure/injectable modules together, plus real calls to `vim.notify`/`vim.api.nvim_buf_set_extmark`. It is verified manually end-to-end in Task 8 against a real git repo and a real `claude` CLI call, which is the only way to validate the actual prompt/response quality (flagged as needing empirical validation in the spec).

- [ ] **Step 1: Implement the generate module**

`lua/review_explain/generate.lua`:

```lua
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
```

- [ ] **Step 2: Implement the recall module**

`lua/review_explain/recall.lua`:

```lua
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
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/review_explain/generate.lua lua/review_explain/recall.lua
git commit -m "review-explain: add generate and recall orchestration"
```

---

### Task 8: Wire into lazy.nvim + keymaps (with live collision check) + manual verification

**Files:**
- Create: `lua/plugins/review-explain.lua`

**Interfaces:**
- Consumes: `review_explain.generate.run`, `review_explain.recall.show`
- Produces: nothing further (this is the leaf wiring task)

- [ ] **Step 1: Check `<leader>ce` for collisions before binding it**

Run:

```bash
nvim --headless -c "lua vim.defer_fn(function() vim.cmd('qa!') end, 300)" -c "lua local maps = vim.api.nvim_get_keymap('x'); for _,m in ipairs(maps) do if m.lhs == ' ce' then print(m.desc) end end" 2>&1
```

If this prints a description, `<leader>ce` is already bound to something — pick a different visual-mode leader combo (e.g. `<leader>cE`) and re-run the check before proceeding. If it prints nothing, `<leader>ce` is free; proceed.

- [ ] **Step 2: Confirm what `K` currently does**

This was already established earlier in this session: LazyVim binds `K` to `vim.lsp.buf.hover()` as a buffer-local keymap set when an LSP client attaches (`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/lsp/init.lua:85`). The plugin below overrides `K` globally with a function that tries `recall.show()` first and falls back to `vim.lsp.buf.hover()`, so buffers without a cached explanation behave exactly as before.

- [ ] **Step 3: Write the plugin spec**

`lua/plugins/review-explain.lua`:

```lua
return {
	dir = vim.fn.stdpath("config"),
	name = "review-explain",
	lazy = false,
	config = function()
		local generate = require("review_explain.generate")
		local recall = require("review_explain.recall")

		vim.keymap.set("x", "<leader>ce", function()
			vim.cmd("normal! \27") -- exit visual mode so '< '> marks are set
			local start_lnum = vim.api.nvim_buf_get_mark(0, "<")[1] - 1
			local end_lnum = vim.api.nvim_buf_get_mark(0, ">")[1] - 1
			generate.run(0, start_lnum, end_lnum)
		end, { desc = "Explain selection with Claude" })

		vim.keymap.set("n", "K", function()
			if not recall.show(0) then
				vim.lsp.buf.hover()
			end
		end, { desc = "Hover / cached explanation" })
	end,
}
```

- [ ] **Step 4: Sync and verify no load errors**

Run: `nvim --headless -c "Lazy! sync" -c "sleep 2" -c "qa!" 2>&1 | tail -20`
Run: `nvim --headless -c "lua local ok, err = pcall(require, 'review_explain.generate'); print(ok, err)" -c "qa!" 2>&1`
Expected: `true	nil`

- [ ] **Step 5: Manual end-to-end verification (real `claude` call — this is the empirical prompt validation the spec calls for)**

In a real git repository with an uncommitted or recent change containing at least one function:

1. Open the file in nvim, visually select a function, press `<leader>ce`.
2. Wait for the "review-explain: explained N function(s)" notification.
3. Inspect the generated cache file: `cat .nvim-review/<relative/path>.json` — confirm it contains a plausible `explanation` string, correct `start_line`/`end_line`, and a `body_hash`.
4. Move the cursor into the explained function, press `K` — confirm the floating window shows the explanation.
5. Move the cursor to a function that was never explained, press `K` — confirm normal LSP hover still runs (or nothing happens if no LSP is attached), with no error.
6. Edit the explained function's body and save. Press `K` again on it — confirm the explanation no longer appears (hash mismatch means "no cache", per the spec's non-goal of silent auto-refresh).

Record what the explanation quality actually looked like — this is the probe-tier prompt validation flagged in the spec's "Open questions" section. If the output is unsatisfying, iterate on `prompt.SYSTEM_PROMPT` in Task 1's file and re-run this verification; no test changes are needed since the prompt text itself isn't asserted against specific content.

- [ ] **Step 6: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/review-explain.lua
git commit -m "review-explain: wire generate/recall into lazy.nvim with K fallback"
```

---

## Self-Review Notes

- **Spec coverage:** generate flow (Task 7/8), recall via K (Task 7/8), cache format matching the spec's JSON shape (Task 3), line-numbers-as-hints resolution via treesitter name+hash (Task 4, used in both generate and recall), `claude -p`-only auth constraint (Task 5's `build_cmd` hard-codes `-p`/`--output-format json`, never touches the SDK), async/non-blocking execution (Task 5's `vim.schedule` + `vim.system`), non-goals respected (no auto-generation on hover — `recall.show` never calls `generate.run`; no auto-refresh — hash mismatch just returns `false`). All covered.
- **Placeholder scan:** no TBD/TODO markers; every step has runnable code or an exact command.
- **Type consistency:** `entries` shape `{name, start_line, end_line, explanation}` is identical across parser (Task 2), generate (Task 7), and the spec's cache JSON (Task 3) — checked field-by-field. `resolve.find_enclosing_function` return shape `{name, start_line, end_line, node}` is used identically in Task 4's own tests, Task 7's `generate.run`, and Task 7's `recall.show`. `client.run`'s `on_done(ok, stdout_or_err)` signature matches its only caller in `generate.run`.
