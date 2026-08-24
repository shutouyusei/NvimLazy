return {
	dir = vim.fn.stdpath("config"),
	name = "review-explain",
	lazy = false,
	config = function()
		local generate = require("review_explain.generate")
		local recall = require("review_explain.recall")

		vim.keymap.set("x", "<leader>ce", function()
			vim.cmd("normal! \27") -- exit visual mode so '< '> marks are set
			local start_lnum = vim.api.nvim_buf_get_mark(0, "<")[1] - 1
			local end_lnum = vim.api.nvim_buf_get_mark(0, ">")[1] - 1
			generate.run(0, start_lnum, end_lnum)
		end, { desc = "Explain selection with Claude" })

		vim.keymap.set("n", "K", function()
			if not recall.show(0) then
				vim.lsp.buf.hover()
			end
		end, { desc = "Hover / cached explanation" })
	end,
}
