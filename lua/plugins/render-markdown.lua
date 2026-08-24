return {
	{ "iamcco/markdown-preview.nvim", enabled = false },
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			heading = {
				sign = false,
				icons = { "● ", "❖ ", "◆ ", "◇ ", "○ ", "◦ " },
				width = "block",
				left_pad = 0,
				right_pad = 2,
				min_width = 40,
			},
			code = {
				sign = false,
				width = "block",
				right_pad = 2,
				border = "thick",
				language_pad = 2,
				highlight_language = "RenderMarkdownCode",
			},
			bullet = {
				icons = { "●", "○", "◆", "◇" },
			},
			checkbox = {
				enabled = true,
				unchecked = { icon = "󰄱 " },
				checked = { icon = " " },
			},
			quote = {
				icon = "▍",
			},
			pipe_table = {
				style = "full",
				border = {
					"╭",
					"┬",
					"╮",
					"├",
					"┼",
					"┤",
					"╰",
					"┴",
					"╯",
					"│",
					"─",
				},
			},
		},
	},
}
