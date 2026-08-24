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
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
	{ "folke/tokyonight.nvim", enabled = false },
}
