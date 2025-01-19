return {
	"milanglacier/minuet-ai.nvim",
	config = function()
		require("minuet").setup({
			notify = "warn",
			context_window = 1600,
			n_completions = 1,
			provider = "openai_fim_compatible",
			provider_options = {
				openai_fim_compatible = {
					api_key = "TERM",
					name = "Ollama",
					end_point = "http://localhost:11434/v1/completions",
					model = "qwen2.5-coder:14b",
					stream = true,
					optional = {
						max_tokens = 32,
						top_p = 0.9,
						stop = { "\n" },
					},
				},
			},
		})
	end,
}
