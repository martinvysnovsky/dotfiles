return {
	"milanglacier/minuet-ai.nvim",
	config = function()
		require("minuet").setup({
			notify = "warn",
			provider = "openai_fim_compatible",
			n_completions = 1,
			context_window = 512,
			provider_options = {
				openai_fim_compatible = {
					api_key = "TERM",
					name = "Ollama",
					end_point = "http://localhost:11434/v1/completions",
					model = "qwen2.5-coder:3b",
					stream = true,
					optional = {
						max_tokens = 256,
						top_p = 0.9,
						stop = { "\n\n" },
						-- stop = { "\n" },
					},
				},
			},
		})
	end,
}
