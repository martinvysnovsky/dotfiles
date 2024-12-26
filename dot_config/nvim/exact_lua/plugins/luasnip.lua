return {
	"L3MON4D3/LuaSnip",
	opts = {
		require("luasnip").filetype_extend("typescriptreact", { "remix" }),
		require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/lua/snippets" }),
	},
}
