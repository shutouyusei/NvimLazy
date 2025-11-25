return {
	"shellRaining/hlchunk.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("hlchunk").setup({
			chunk = {
				enable = true,
				-- 白背景でもくっきり見える鮮やかなブルー
				style = "#00aaff",
			},
			line_num = {
				enable = true,
				-- アクセントになる鮮やかなピンク/赤
				style = "#ff007c",
			},
			blank = {
				enable = true,
				chars = {
					" ",
				},
				-- 【重要】白背景用設定
				-- ここは濃い色にすると文字が読めなくなるため、
				-- 「ほんのり色づく」程度の薄いパステルカラーにしています。
				style = {
					{ bg = "#fff0f5" }, -- LavenderBlush (薄いピンク)
					{ bg = "#f0fff0" }, -- Honeydew (薄い緑)
					{ bg = "#e6e6fa" }, -- Lavender (薄い紫)
					{ bg = "#e0ffff" }, -- LightCyan (薄い水色)
				},
			},
		})
	end,
}
