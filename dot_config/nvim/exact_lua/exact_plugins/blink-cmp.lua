return {
	"saghen/blink.cmp",
	opts = {
		sources = {
			default = { "lsp", "path", "buffer", "minuet" },
			providers = {
				minuet = {
					name = "minuet",
					module = "minuet.blink",
					async = true,
					timeout_ms = 3000,
					score_offset = 50,
				},
			},
		},
		completion = { trigger = { prefetch_on_insert = false } },
	},
}
