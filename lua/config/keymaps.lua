-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- ESC設定
vim.keymap.set("i", "jj", "<ESC>")
-- ターミナルノーマルモードへの変更
vim.keymap.set("t", "jj", "<C-\\><C-n>")
-- terminal
vim.keymap.set("n", "<leader>t", function()
  Snacks.terminal("powershell", { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
vim.keymap.set("t", "<leader>t", "<cmd>close<CR>", { desc = "Terminal (Root Dir)" })
