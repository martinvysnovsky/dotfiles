return {
	"epwalsh/obsidian.nvim",
	event = {
		"BufReadPre " .. vim.fn.expand("~") .. "/obsidian/**/**.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/obsidian/**/**.md",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/obsidian",
			},
		},
		templates = {
			folder = "Templates",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
			-- A map for custom variables, the key should be the variable and the value a function
			substitutions = {},
		},
		daily_notes = {
			folder = "Daily",
			date_format = "%Y-%m-%d",
			default_tags = { "daily-notes" },
			template = "Daily.md",
		},
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url }) -- linux
		end,
	},
}
