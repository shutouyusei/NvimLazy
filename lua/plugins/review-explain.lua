local claude_win_opts = {
	win = {
		position = "float",
		width = 0.85,
		height = 0.85,
		border = "rounded",
		title = " Claude Code ",
		title_pos = "center",
	},
}

-- Remembered for the lifetime of this nvim process: the New-session vs
-- Agents choice is only asked once, then <leader>ac just toggles it.
local claude_cmd = nil

local function toggle_claude()
	if claude_cmd then
		Snacks.terminal.toggle(claude_cmd, claude_win_opts)
		return
	end

	-- "claude agents" is Claude Code's own background-agent dashboard
	-- (FleetView) -- pick a running session there to attach to the main
	-- research agent, instead of a fresh disposable one
	local choices = { "New session", "Agents (attach to running agent)" }
	vim.ui.select(choices, { prompt = "Claude Code" }, function(choice)
		if not choice then
			return
		end
		claude_cmd = choice == "New session" and "claude" or { "claude", "agents" }
		Snacks.terminal.toggle(claude_cmd, claude_win_opts)
	end)
end

return {
	"shutouyusei/review-explain.nvim",
	dev = true, -- use ~/projects/review-explain.nvim (lazy.nvim's dev.path default) instead of GitHub
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	keys = {
		{
			"<leader>ac",
			toggle_claude,
			-- also bind in terminal mode: while the float is focused and
			-- claude is running, terminal-insert keystrokes go straight to
			-- the job, so a normal-mode-only mapping never fires there.
			mode = { "n", "t" },
			desc = "Toggle Claude Code (float)",
		},
	},
	opts = {
		language = "Japanese",
		-- K is registered through nvim-lspconfig.lua's servers['*'].keys
		-- instead (see README: LazyVim + Snacks.nvim users) -- Snacks'
		-- own K->hover registration on LspAttach would otherwise overwrite
		-- a plain FileType-time K mapping on any LSP-attached buffer.
		register_hover_keymap = false,
	},
}
