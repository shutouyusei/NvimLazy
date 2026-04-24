return {
	-- add any tools you want to have installed below
	{
		"mason-org/mason.nvim",
		cmd = {
			"Mason",
			"MasonInstall",
			"MasonUninstall",
			"MasonUninstallAll",
			"MasonLog",
			"MasonUpdate",
		},
		opts = {
			ensure_installed = {
				-- formatters
				"stylua",
				"shfmt",
				-- linters
				"shellcheck",
				"markdownlint-cli2",
				-- language servers
				"bash-language-server",
				"clangd",
				"harper-ls",
				"json-lsp",
				"lua-language-server",
				"marksman",
				"taplo",
				-- debuggers
				"codelldb",
			},
		},
	},
}
