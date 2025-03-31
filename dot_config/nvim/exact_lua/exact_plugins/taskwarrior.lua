return {
	{
		"huantrinh1802/m_taskwarrior_d.nvim",
		version = "*",
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
				pattern = "*.md,*.markdown",
				callback = function()
					vim.cmd("TWSyncTasks")
				end,
			})
		end,
		ui = {
			checkboxes = {
				[" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
				["x"] = { char = "", hl_group = "ObsidianDone" },
				[">"] = { char = "", hl_group = "ObsidianRightArrow" },
				["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
			},
			hl_groups = {
				ObsidianTodo = { bold = true, fg = "#f78c6c" },
				ObsidianDone = { bold = true, fg = "#89ddff" },
				ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
				ObsidianTilde = { bold = true, fg = "#ff5370" },
				ObsidianBullet = { bold = true, fg = "#89ddff" },
				ObsidianRefText = { underline = true, fg = "#008080" },
				ObsidianExtLinkIcon = { fg = "#008080" },
				ObsidianTag = { italic = true, fg = "#89ddff" },
				ObsidianHighlightText = { bg = "#75662e" },
			},
		},
	},
}
