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
	config = function(_, opts)
		require("image").setup(opts)

		-- SVG fix: ImageMagick's default policy denies SVG, so route .svg through
		-- rsvg-convert and cache results persistently in ~/.cache/nvim-image-svg
		-- keyed by absolute path + mtime. Skipping rsvg on warm cache makes image
		-- re-rendering on save / re-open effectively free.
		if vim.fn.executable("rsvg-convert") == 1 then
			local cache_dir = vim.fn.stdpath("cache") .. "/nvim-image-svg"
			vim.fn.mkdir(cache_dir, "p")

			-- Match image.nvim's internal require path exactly (slashes, not dots).
			-- Neovim caches `package.loaded` by the literal string.
			local processor = require("image/processors/magick_cli")
			local orig_convert = processor.convert_to_png
			processor.convert_to_png = function(path, output_path)
				if not path:lower():match("%.svg$") then
					return orig_convert(path, output_path)
				end

				local abs = vim.fn.fnamemodify(path, ":p")
				local mtime = vim.fn.getftime(abs)
				local key = vim.fn.sha256(abs .. ":" .. tostring(mtime))
				local cached = cache_dir .. "/" .. key .. ".png"

				if vim.fn.filereadable(cached) == 1 then
					if output_path and output_path ~= cached then
						vim.fn.writefile(vim.fn.readfile(cached, "b"), output_path, "b")
						return output_path
					end
					return cached
				end

				local target = output_path or cached
				local result = vim.system({ "rsvg-convert", "-o", target, abs }, { text = true }):wait()
				if result.code ~= 0 then
					error("rsvg-convert failed: " .. (result.stderr or ""))
				end
				-- populate the persistent cache too
				if target ~= cached then
					pcall(vim.fn.writefile, vim.fn.readfile(target, "b"), cached, "b")
				end
				return target
			end
		end
	end,
}
