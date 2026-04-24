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

-- :ConfigDoctor — verify every external binary this config depends on.
-- New-machine sanity check: run after install-deps.sh to see what (if anything) is missing.
vim.api.nvim_create_user_command("ConfigDoctor", function()
	local checks = {
		{ name = "git", why = "vcs, LazyVim" },
		{ name = "curl", why = "plugin downloads" },
		{ name = "rg", why = "ripgrep — LazyVim grep, snacks picker" },
		{ name = "fd", why = "fast file finder (fdfind symlinked)" },
		{ name = "lazygit", why = "<leader>gg git UI" },
		{ name = "node", why = "markdown-preview, some Mason tools" },
		{ name = "npm", why = "Mason installs via npm for some LSPs" },
		{ name = "rsvg-convert", why = "image.nvim SVG rendering" },
		{ name = "pdftoppm", why = "latex pdf_preview util" },
		{ name = "zathura", why = "vimtex PDF viewer" },
		{ name = "harper-ls", why = "Mason-installed grammar LSP" },
		{ name = "clangd", why = "Mason-installed C/C++ LSP" },
		{ name = "stylua", why = "Mason-installed Lua formatter" },
	}
	local ok, missing = {}, {}
	for _, c in ipairs(checks) do
		local path = vim.fn.exepath(c.name)
		if path ~= "" then
			table.insert(ok, string.format("  ✅ %-16s %s", c.name, path))
		else
			table.insert(missing, string.format("  ❌ %-16s (%s)", c.name, c.why))
		end
	end
	local lines = { "=== ConfigDoctor ===", "" }
	vim.list_extend(lines, ok)
	if #missing > 0 then
		table.insert(lines, "")
		table.insert(lines, "Missing:")
		vim.list_extend(lines, missing)
		table.insert(lines, "")
		table.insert(lines, "Fix: re-run install-deps.sh or `:Mason` for Mason tools.")
	end
	local fonts = vim.fn.systemlist({ "fc-list", ":family" })
	local has_nerd = false
	for _, f in ipairs(fonts) do
		if f:lower():match("nerd") then
			has_nerd = true
			break
		end
	end
	table.insert(lines, "")
	table.insert(lines, has_nerd and "  ✅ Nerd Font detected" or "  ❌ No Nerd Font found — icons will render as □")
	vim.notify(table.concat(lines, "\n"), #missing > 0 and vim.log.levels.WARN or vim.log.levels.INFO, { title = "ConfigDoctor" })
end, { desc = "Verify all external binaries this config depends on" })

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
