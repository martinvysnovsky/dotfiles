return {
	"epwalsh/obsidian.nvim",
	event = {
		"BufReadPre " .. vim.fn.expand("~") .. "/Obsidian/**/**.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/Obsidian/**/**.md",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/Obsidian",
			},
		},
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url }) -- linux
		end,
	},
}
