-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

require("util.pdf_preview").setup()

-- check for upstream config updates, at most once per 24h
local function check_config_updates()
	local config_dir = vim.fn.stdpath("config")
	local stamp = vim.fn.stdpath("state") .. "/config-update-check"
	local now = os.time()
	local last = 0
	local f = io.open(stamp, "r")
	if f then
		last = tonumber(f:read("*l") or "0") or 0
		f:close()
	end
	if now - last < 24 * 60 * 60 then
		return
	end

	vim.system({ "git", "-C", config_dir, "fetch" }, { text = true }, function(fetch_obj)
		if fetch_obj.code ~= 0 then
			return
		end

		local w = io.open(stamp, "w")
		if w then
			w:write(tostring(now))
			w:close()
		end

		vim.system({ "git", "-C", config_dir, "rev-list", "HEAD..@{u}", "--count" }, { text = true }, function(check_obj)
			if check_obj.code == 0 then
				local count = tonumber(vim.trim(check_obj.stdout))

				if count and count > 0 then
					vim.schedule(function()
						vim.notify("⚡ 設定ファイルの更新が " .. count .. " 件あります。\n:ConfigPull で更新できます。", vim.log.levels.INFO, { title = "Neovim Config" })
					end)
				end
			end
		end)
	end)
end

check_config_updates()

vim.api.nvim_create_user_command("ConfigPull", function()
	local config_dir = vim.fn.stdpath("config")
	vim.notify("更新を開始します...", vim.log.levels.INFO)

	vim.fn.jobstart({ "git", "-C", config_dir, "pull", "--rebase", "--autostash" }, {
		on_exit = function(_, code)
			if code == 0 then
				vim.notify("更新が完了しました。再起動を推奨します。", vim.log.levels.INFO)
			else
				vim.notify("更新に失敗しました。", vim.log.levels.ERROR)
			end
		end,
	})
end, {})
