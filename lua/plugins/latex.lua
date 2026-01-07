return {
	"lervag/vimtex",
	lazy = false,
	-- change pdf viewer for your os
	init = function()
		vim.g.vimtex_view_method = "skim"
	end,
}
