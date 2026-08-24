return {
	dir = vim.fn.stdpath("config"),
	name = "review-explain",
	lazy = false,
	config = function()
		local generate = require("review_explain.generate")

		-- Background for functions that already have an explanation matching
		-- their current content, so they're visible without pressing K on
		-- each one. Linked (not hardcoded) so it follows the colorscheme;
		-- `default = true` lets a user override it in their own config.
		vim.api.nvim_set_hl(0, "ReviewExplainExplained", { link = "Folded", default = true })

		vim.keymap.set("x", "<leader>ce", function()
			vim.cmd("normal! \27") -- exit visual mode so '< '> marks are set
			local start_lnum = vim.api.nvim_buf_get_mark(0, "<")[1] - 1
			local end_lnum = vim.api.nvim_buf_get_mark(0, ">")[1] - 1
			generate.run(0, start_lnum, end_lnum)
		end, { desc = "Explain selection with Claude" })

		-- K/hover recall for LSP-attached buffers is registered through
		-- LazyVim's own servers['*'].keys mechanism (nvim-lspconfig.lua),
		-- not here -- Snacks.nvim registers LazyVim's default K->hover map
		-- ~100ms after LspAttach fires (vim.schedule + debounce), which
		-- would silently overwrite a K map set independently via our own
		-- LspAttach autocmd. Routing through servers['*'].keys instead
		-- means Snacks' own "newer keymaps first" precedence keeps our
		-- mapping intact once LSP does attach.
		--
		-- But some buffers never get an LSP client at all -- e.g.
		-- diffview.nvim's file panes set buftype "nowrite"/"acwrite",
		-- and LSP clients only auto-attach to buftype=="" buffers -- so
		-- recall would never be reachable there under the LSP-gated path
		-- alone. This FileType autocmd covers that case: it sets K
		-- unconditionally, buffer-local, for any filetype not in the
		-- excluded set below. recall.show() already degrades gracefully
		-- with no LSP client attached (empty hover, cache-only or a
		-- plain notify), so it's safe to always route through it here.
		local excluded_filetypes = {
			help = true,
			man = true,
			qf = true,
			checkhealth = true,
			lazy = true,
			mason = true,
			lspinfo = true,
			query = true,
		}

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("review_explain_filetype", { clear = true }),
			callback = function(args)
				if excluded_filetypes[args.match] then
					return
				end
				vim.keymap.set("n", "K", function()
					require("review_explain.recall").show(args.buf)
				end, { buffer = args.buf, desc = "Hover / cached explanation" })

				require("review_explain.recall").highlight_buffer(args.buf)
			end,
		})
	end,
}
