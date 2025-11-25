-- return {
-- 	{
-- 		"folke/tokyonight.nvim",
-- 		lazy = false,
-- 		priority = 1000,
-- 		opts = {
-- 			style = "day", -- "night", "storm", "moon", "day" から選択
-- 			transparent = true, -- 背景を透明にする
-- 			terminal_colors = true,
-- 			styles = {
-- 				comments = { italic = true },
-- 				keywords = { italic = false },
-- 				functions = { bold = true },
-- 				variables = {},
-- 			},
-- 		},
-- 		config = function(_, opts)
-- 			require("tokyonight").setup(opts)
-- 			vim.cmd.colorscheme("tokyonight")
-- 		end,
-- 	},
-- }
return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		opts = {
			flavour = "latte",
			background = {
				light = "latte",
				dark = "mocha",
			},
			transparent_background = true,
			styles = {
				comments = { "italic" },
				keywords = { "italic" },
				functions = { "bold" },
				variables = {},
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
