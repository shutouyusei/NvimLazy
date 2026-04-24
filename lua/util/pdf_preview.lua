local M = {}

function M.render_page(pdf_path, page, out_dir)
	local prefix = out_dir .. "/page"
	local result = vim
		.system({
			"pdftoppm",
			"-png",
			"-r",
			"150",
			"-f",
			tostring(page),
			"-l",
			tostring(page),
			"-singlefile",
			pdf_path,
			prefix,
		}, { text = true })
		:wait()

	if result.code ~= 0 then
		vim.notify("pdftoppm failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
		return nil
	end
	return prefix .. ".png"
end

function M.refresh(state)
	local png = M.render_page(state.pdf_path, state.page, state.tmp_dir)
	if not png then
		return
	end

	if state.image then
		state.image:clear()
	end

	local image = require("image").from_file(png, {
		window = state.win,
		buffer = state.buf,
		x = 0,
		y = 0,
		max_width_window_percentage = 100,
		max_height_window_percentage = 100,
	})
	image:render()
	state.image = image
end

function M.open_preview()
	local tex = vim.api.nvim_buf_get_name(0)
	if not tex:match("%.tex$") then
		vim.notify("Not a .tex file", vim.log.levels.WARN)
		return
	end

	local pdf_path = tex:gsub("%.tex$", ".pdf")
	local tmp_dir = vim.fn.tempname()
	vim.fn.mkdir(tmp_dir, "p")

	vim.cmd("rightbelow vsplit")
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buftype = "nofile"
	vim.cmd("wincmd p")

	local state = {
		pdf_path = pdf_path,
		page = 1,
		win = win,
		buf = buf,
		tmp_dir = tmp_dir,
	}

	local timer = vim.uv.new_timer()
	local function debounced()
		timer:stop()
		timer:start(
			150,
			0,
			vim.schedule_wrap(function()
				if vim.api.nvim_buf_is_valid(state.buf) then
					M.refresh(state)
				end
			end)
		)
	end

	local dir = vim.fn.fnamemodify(pdf_path, ":h")
	local name = vim.fn.fnamemodify(pdf_path, ":t")
	local watcher = vim.uv.new_fs_event()
	watcher:start(dir, {}, function(err, fname)
		if err or fname ~= name then
			return
		end
		debounced()
	end)
	state.watcher = watcher
	state.timer = timer

	if vim.fn.filereadable(pdf_path) == 1 then
		M.refresh(state)
	end

	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		callback = function()
			watcher:stop()
			timer:stop()
			vim.fn.delete(tmp_dir, "rf")
		end,
	})

	local function next_page()
		state.page = state.page + 1
		M.refresh(state)
	end
	local function prev_page()
		if state.page > 1 then
			state.page = state.page - 1
			M.refresh(state)
		end
	end
	vim.keymap.set("n", "]p", next_page, { buffer = buf, desc = "PDF next page" })
	vim.keymap.set("n", "[p", prev_page, { buffer = buf, desc = "PDF prev page" })

	return state
end

function M.setup()
	vim.api.nvim_create_user_command("LatexPreview", function()
		M.open_preview()
	end, { desc = "Open inline PDF preview of current .tex" })
end

return M
