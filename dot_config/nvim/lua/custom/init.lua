vim.g.copilot_assume_mapped = true

vim.opt.clipboard = ""

-- Keep search results centred
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")

-- leep 2 lines in the bottom of screeen
vim.o.scrolloff=2

vim.keymap.set("n", "gf", function()
  if require("obsidian").util.cursor_on_markdown_link() then
    return "<cmd>ObsidianFollowLink<CR>"
  else
    return "gf"
  end
end, { noremap = false, expr = true })

