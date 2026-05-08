return {
	"folke/snacks.nvim",
	opts = {
		lazygit = {
			theme = {
				inactiveBorderColor = { fg = "Comment" },
			},
		},
		terminal = {
			win = {
				keys = {
					nav_h = { "<C-h>", function(self)
						if self:is_floating() then vim.fn.system("tmux select-pane -L")
						else vim.cmd.wincmd("h") end
					end, desc = "Navigate Left", mode = "t" },
					nav_j = { "<C-j>", function(self)
						if self:is_floating() then vim.fn.system("tmux select-pane -D")
						else vim.cmd.wincmd("j") end
					end, desc = "Navigate Down", mode = "t" },
					nav_k = { "<C-k>", function(self)
						if self:is_floating() then vim.fn.system("tmux select-pane -U")
						else vim.cmd.wincmd("k") end
					end, desc = "Navigate Up", mode = "t" },
					nav_l = { "<C-l>", function(self)
						if self:is_floating() then vim.fn.system("tmux select-pane -R")
						else vim.cmd.wincmd("l") end
					end, desc = "Navigate Right", mode = "t" },
				},
			},
		},
	},
}
