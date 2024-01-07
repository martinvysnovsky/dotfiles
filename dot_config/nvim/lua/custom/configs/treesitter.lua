local options = {
  ensure_installed = {
    "lua",
    "markdown",
    "markdown_inline",
    "javascript",
    "typescript",
    "tsx",
    "html",
    "css",
    "json",
    "yaml",
    "bash",
    "regex",
    "dockerfile",
    "graphql",
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = { "markdown" },
  },
}

return options
