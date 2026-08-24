return {
	"shutouyusei/review-explain.nvim",
	dev = true, -- use ~/projects/review-explain.nvim (lazy.nvim's dev.path default) instead of GitHub
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {
		language = "Japanese",
		-- K is registered through nvim-lspconfig.lua's servers['*'].keys
		-- instead (see README: LazyVim + Snacks.nvim users) -- Snacks'
		-- own K->hover registration on LspAttach would otherwise overwrite
		-- a plain FileType-time K mapping on any LSP-attached buffer.
		register_hover_keymap = false,
	},
}
