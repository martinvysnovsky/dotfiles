return {
	{
		"Exafunction/codeium.nvim",
		cmd = "Codeium",
		build = ":Codeium Auth",
		opts = {},
	},

	{
		"nvim-cmp",
		opts = {
			experimental = {
				ghost_text = false,
			},
		},
	},
}
