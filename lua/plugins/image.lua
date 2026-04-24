return {
	"3rd/image.nvim",
	build = false,
	ft = { "markdown", "norg", "tex", "typst", "quarto" },
	opts = {
		backend = "kitty",
		processor = "magick_cli",
		max_width = 100,
		max_height = 50,
		max_height_window_percentage = math.huge,
		max_width_window_percentage = math.huge,
		window_overlap_clear_enabled = true,
	},
}
