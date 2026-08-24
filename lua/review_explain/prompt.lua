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
