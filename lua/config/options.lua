-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.encoding = "utf-8"

vim.scriptencoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = "ucs-bom,utf-8,euc-jp,cp932"
vim.opt.shiftwidth = 4
vim.opt.ambiwidth = "single"

-- color

-- language
vim.opt.spell = true
vim.opt.spelllang = { "en_us", "cjk" }

-- fold method (nvim-ufo drives folds; requires manual)
vim.opt.foldmethod = "manual"
vim.opt.foldlevelstart = 99

-- opacity
vim.opt.winblend = 10
vim.opt.pumblend = 10
