return {
	"nvim-treesitter/nvim-treesitter",
	-- there is an issue with tests in 0.9.2
	version = "0.9.1",
	opts = function(_, opts)
		table.insert(opts.ensure_installed, {
			"pug",
		})
	end,
}
