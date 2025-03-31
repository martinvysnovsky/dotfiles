return {
	{
		"huantrinh1802/m_taskwarrior_d.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		config = function()
			require("m_taskwarrior_d").setup()

			vim.api.nvim_set_keymap(
				"n",
				"<leader>te",
				"<cmd>TWEditTask<cr>",
				{ desc = "TaskWarrior Edit", noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap("n", "<leader>tv", "<cmd>TWView<cr>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>tu", "<cmd>TWUpdateCurrent<cr>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>tc", "<cmd>TWToggle<cr>", { silent = true })

			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
				group = vim.api.nvim_create_augroup("TWTask", { clear = true }),
				pattern = "*.md",
				callback = function()
					vim.cmd("TWSyncTasks")
				end,
			})
		end,
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("render-markdown").setup({
				checkbox = {
					enabled = true,
					checked = {
						-- Replaces '[x]' of 'task_list_marker_checked'
						icon = " ",
						-- Highligh for the checked icon
						highlight = "RenderMarkdownChecked",
					},
					custom = {
						started = { raw = "[>]", rendered = " ", highlight = "@markup.raw" },
						deleted = { raw = "[~]", rendered = " ", highlight = "@markup.raw" },
					},
				},
			})
		end,
	},
}
