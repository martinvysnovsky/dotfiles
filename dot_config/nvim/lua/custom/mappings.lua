local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<C-h>"] = { "<cmd> TmuxNavigateLeft<CR>", "window left" },
    ["<C-l>"] = { "<cmd> TmuxNavigateRight<CR>", "window right" },
    ["<C-j>"] = { "<cmd> TmuxNavigateDown<CR>", "window down" },
    ["<C-k>"] = { "<cmd> TmuxNavigateUp<CR>", "window up" },

    -- copy/paste to system clipboard
    ["<S-y><S-y>"] = { '"+yy' },
    ["<S-y>"] = { '"+y' },
  },

  v = {
    -- copy/paste to system clipboard
    ["<S-y><S-y>"] = { '"+yy' },
    ["<S-y>"] = { '"+y' },
  },
}

local function open_lazygit()
  local terminal = require "nvterm.terminal"
  local existing_terminals = terminal.list_terms()

  terminal.toggle "float"

  -- open lazygit if we just started a new terminal
  if #existing_terminals == 0 then
    terminal.send("lazygit", "float")
  end
end

M.nvterm = {
  t = {
    -- toggle in terminal mode
    ["<leader>i"] = {
      open_lazygit,
      "Toggle floating term with lazygit",
    },
  },

  n = {
    -- toggle in normal mode
    ["<leader>i"] = {
      open_lazygit,
      "Toggle floating term with lazygit",
    },
  },
}

M.dap = {
  plugin = true,
  n = {
    ["<leader>db"] = {
      "<cmd> DapToggleBreakpoint <CR>",
      "Add breakpoint at line"
    },
    ["<leader>dr"] = {
      "<cmd> DapContinue <CR>",
      "Run or continue the debbuger"
    }
  }
}

return M
