return {
	"milanglacier/minuet-ai.nvim",
	config = function()
		require("minuet").setup({
			provider = "openai_fim_compatible",
			n_completions = 1,
			context_window = 1024,
			provider_options = {
				openai_fim_compatible = {
					api_key = "TERM",
					name = "Ollama",
					end_point = "http://localhost:11434/v1/completions",
					model = "deepseek-coder-v2:latest",
					optional = {
						max_tokens = 56,
						top_p = 0.9,
					},
				},
			},
		})
	end,
}
