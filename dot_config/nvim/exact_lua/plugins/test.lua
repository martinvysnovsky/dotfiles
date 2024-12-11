return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"haydenmeade/neotest-jest",
		},
		keys = {
			{
				"<leader>tl",
				function()
					require("neotest").run.run_last()
				end,
				desc = "Run Last Test",
			},
			{
				"<leader>tL",
				function()
					require("neotest").run.run_last({ strategy = "dap" })
				end,
				desc = "Debug Last Test",
			},
			{
				"<leader>tw",
				"<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>",
				desc = "Run Watch",
			},
		},
		opts = function(_, opts)
			table.insert(
				opts.adapters,
				require("neotest-jest")({
					jestCommand = "npm test --",
					jestConfigFile = function()
						local file = vim.fn.expand("%")

						if string.find(file, "e2e%-spec") then
							return vim.fn.getcwd() .. "/test/jest-e2e.config.ts"
						end

						return vim.fn.getcwd() .. "/jest.config.ts"
					end,
					env = { CI = true },
					cwd = function()
						return vim.fn.getcwd()
					end,
				})
			)
		end,
	},
}
