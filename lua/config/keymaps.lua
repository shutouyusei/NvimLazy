-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- ESC設定
vim.keymap.set("i", "jj", "<ESC>")
-- ターミナルノーマルモードへの変更
vim.keymap.set("t", "jj", "<C-\\><C-n>")
