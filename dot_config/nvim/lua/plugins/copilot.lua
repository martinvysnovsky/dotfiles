vim.g.copilot_assume_mapped = true

return {
	{
		"zbirenbaum/copilot.lua",
		ft = {
			"yaml",
			"markdown",
			"terraform",
			"javascript",
			"typescript",
			"gitcommit",
			"gitrebase",
			"lua",
		},
		opts = {
			suggestion = {
				enabled = true,
				auto_trigger = true,
			},
		},
	},

	{ "zbirenbaum/copilot-cmp", enabled = false },

	{
		"L3MON4D3/LuaSnip",
		keys = function()
			return {} -- disable Tab
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		opts = function(_, opts)
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local copilot = require("copilot.suggestion")

			opts.mapping = vim.tbl_extend("force", opts.mapping, {
				["<Tab>"] = cmp.mapping(function(fallback)
					if copilot.is_visible() then
						copilot.accept()
					elseif luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),
			})
		end,
	},
}
