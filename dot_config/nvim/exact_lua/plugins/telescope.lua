return {
	{
		"nvim-telescope/telescope.nvim",
		keys = {
			{ "<leader>/", require("custom/telescope/multi-ripgrep"), desc = "Grep (Root Dir)" },
		},
	},
}
