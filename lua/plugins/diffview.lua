return {
	"dlyongemallo/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewToggle", "DiffviewFileHistory", "DiffviewClose" },
	keys = {
		{ "<leader>gv", "<cmd>DiffviewToggle<cr>", desc = "Diff View (working tree, toggle)" },
		{
			"<leader>gl",
			function()
				if require("diffview.lib").get_current_view() then
					require("diffview").close()
				else
					vim.cmd("DiffviewFileHistory")
				end
			end,
			desc = "File History (toggle)",
		},
		{
			"<leader>gl",
			"<esc><cmd>'<,'>DiffviewFileHistory<cr>",
			mode = "v",
			desc = "File History (selection)",
		},
	},
	opts = {},
}
