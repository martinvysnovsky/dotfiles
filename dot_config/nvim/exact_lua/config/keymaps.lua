-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local set = vim.keymap.set

set("n", "<S-y><S-y>", '"+yy', { desc = "Copy line to system clipboard" })
set("n", "<S-y>", '"+y', { desc = "Copy selection to system clipboard" })
set("v", "<S-y><S-y>", '"+yy', { desc = "Copy line to system clipboard" })
set("v", "<S-y>", '"+y', { desc = "Copy selection to system clipboard" })

set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
