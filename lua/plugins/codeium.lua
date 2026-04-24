return {
	{
		"Exafunction/codeium.nvim",
		config = function(_, opts)
			require("codeium").setup(opts)

			-- Skip codeium on non-file buffers (terminals like term://, nofile, prompt, etc.).
			-- Without this, codeium submits a URI like `//term://...` that its Go backend
			-- rejects with: invalid_argument: empty share name for UNC-like path.
			local vt = require("codeium.virtual_text")
			local orig_filetype_enabled = vt.filetype_enabled
			vt.filetype_enabled = function(bufnr)
				if vim.bo[bufnr].buftype ~= "" then
					return false
				end
				return orig_filetype_enabled(bufnr)
			end
		end,
	},
}
