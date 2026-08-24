local plenary_dir = vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim")
local nvim_treesitter_dir = vim.fn.expand("~/.local/share/nvim/lazy/nvim-treesitter")
local config_dir = vim.fn.getcwd()

vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(nvim_treesitter_dir)
vim.opt.rtp:append(config_dir)

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
