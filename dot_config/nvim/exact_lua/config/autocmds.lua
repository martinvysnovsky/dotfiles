-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Disable autoformat for handlebars files
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "handlebars" },
	callback = function()
		vim.b.autoformat = false
	end,
})
