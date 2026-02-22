-- Minimale Neovim-Konfiguration nur für Tests
-- Verhindert das Laden der normalen init.lua

-- Füge das Plugin-Verzeichnis hinzu
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Füge benötigte Plugins hinzu
local data_path = vim.fn.stdpath("data")
vim.opt.runtimepath:append(data_path .. "/lazy/plenary.nvim")
vim.opt.runtimepath:append(data_path .. "/lazy/sqlite.lua")

-- Deaktiviere unnötige Dinge für Tests
vim.opt.swapfile = false
vim.opt.backup = false