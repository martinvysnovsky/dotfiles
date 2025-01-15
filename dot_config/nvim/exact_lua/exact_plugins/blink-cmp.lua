return {
	"saghen/blink.cmp",
	opts = {
		sources = {
			default = { "lsp", "path", "snippets", "buffer", "minuet" },
			providers = {
				minuet = {
					name = "minuet",
					module = "minuet.blink",
					score_offset = 8,
				},
			},
		},
	},
}
