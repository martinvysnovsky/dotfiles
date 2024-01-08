local cmp = require("cmp")

local plugins = {
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"lua-language-server",
				"eslint-lsp",
				"prettier",
				"typescript-language-server",
				"js-debug-adapter",
				"ltex-ls",
				"graphql-language-service-cli",
				"terraform-ls",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			require("plugins.configs.lspconfig")
			require("custom.configs.lspconfig")
		end,
	},
	{
		"jose-elias-alvarez/null-ls.nvim",
		event = "VeryLazy",
		opts = function()
			return require("custom.configs.null-ls")
		end,
	},
	{
		"mfussenegger/nvim-dap",
		config = function()
			require("custom.configs.dap")
			require("core.utils").load_mappings("dap")
		end,
	},
	{
		"mxsdev/nvim-dap-vscode-js",
		dependencies = { "mfussenegger/nvim-dap" },
	},
	{
		"rcarriga/nvim-dap-ui",
		event = "VeryLazy",
		dependencies = "mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			require("dapui").setup()
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
	{
		"max397574/better-escape.nvim",
		event = "InsertEnter",
		config = function()
			require("better_escape").setup()
		end,
	},
	{
		"christoomey/vim-tmux-navigator",
		lazy = false,
	},
	{
		"github/copilot.vim",
		lazy = false,
	},
	{
		"hrsh7th/nvim-cmp",
		opts = {
			mapping = {
				["<Up>"] = cmp.mapping.select_prev_item(),
				["<Down>"] = cmp.mapping.select_next_item(),
				["<Tab>"] = cmp.mapping(function(fallback)
					fallback()
				end, {
					"i",
					"s",
				}),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					fallback()
				end, {
					"i",
					"s",
				}),
			},
		},
	},
	{
		"jackMort/ChatGPT.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("chatgpt").setup({
				api_key_cmd = "pass openai/api_key",
			})
			local chatgpt = require("chatgpt")
			require("which-key").register({
				p = {
					name = "ChatGPT",
					e = {
						function()
							chatgpt.edit_with_instructions()
						end,
						"Edit with instructions",
					},
				},
			}, {
				prefix = "<leader>",
				mode = "v",
			})
		end,
	},
	{
		"NvChad/nvterm",
		opts = {
			terminals = {
				type_opts = {
					float = {
						relative = "editor",
						row = 0.05,
						col = 0.05,
						width = 0.9,
						height = 0.8,
						border = "single",
					},
				},
			},
		},
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
		lazy = false,
	},
	{
		"ldelossa/gh.nvim",
		dependencies = { "ldelossa/litee.nvim" },
		config = function()
			require("litee.lib").setup()
			require("litee.gh").setup({
				-- deprecated, around for compatability for now.
				jump_mode = "invoking",
				-- remap the arrow keys to resize any litee.nvim windows.
				map_resize_keys = false,
				-- do not map any keys inside any gh.nvim buffers.
				disable_keymaps = false,
				-- the icon set to use.
				icon_set = "default",
				-- any custom icons to use.
				icon_set_custom = nil,
				-- whether to register the @username and #issue_number omnifunc completion
				-- in buffers which start with .git/
				git_buffer_completion = true,
				-- defines keymaps in gh.nvim buffers.
				keymaps = {
					-- when inside a gh.nvim panel, this key will open a node if it has
					-- any futher functionality. for example, hitting <CR> on a commit node
					-- will open the commit's changed files in a new gh.nvim panel.
					open = "<CR>",
					-- when inside a gh.nvim panel, expand a collapsed node
					expand = "zo",
					-- when inside a gh.nvim panel, collpased and expanded node
					collapse = "zc",
					-- when cursor is over a "#1234" formatted issue or PR, open its details
					-- and comments in a new tab.
					goto_issue = "gd",
					-- show any details about a node, typically, this reveals commit messages
					-- and submitted review bodys.
					details = "d",
					-- inside a convo buffer, submit a comment
					submit_comment = "<C-s>",
					-- inside a convo buffer, when your cursor is ontop of a comment, open
					-- up a set of actions that can be performed.
					actions = "<C-a>",
					-- inside a thread convo buffer, resolve the thread.
					resolve_thread = "<C-r>",
					-- inside a gh.nvim panel, if possible, open the node's web URL in your
					-- browser. useful particularily for digging into external failed CI
					-- checks.
					goto_web = "gx",
				},
			})
			local wk = require("which-key")
			wk.register({
				g = {
					name = "+Git",
					h = {
						name = "+Github",
						c = {
							name = "+Commits",
							c = { "<cmd>GHCloseCommit<cr>", "Close" },
							e = { "<cmd>GHExpandCommit<cr>", "Expand" },
							o = { "<cmd>GHOpenToCommit<cr>", "Open To" },
							p = { "<cmd>GHPopOutCommit<cr>", "Pop Out" },
							z = { "<cmd>GHCollapseCommit<cr>", "Collapse" },
						},
						i = {
							name = "+Issues",
							p = { "<cmd>GHPreviewIssue<cr>", "Preview" },
						},
						l = {
							name = "+Litee",
							t = { "<cmd>LTPanel<cr>", "Toggle Panel" },
						},
						r = {
							name = "+Review",
							b = { "<cmd>GHStartReview<cr>", "Begin" },
							c = { "<cmd>GHCloseReview<cr>", "Close" },
							d = { "<cmd>GHDeleteReview<cr>", "Delete" },
							e = { "<cmd>GHExpandReview<cr>", "Expand" },
							s = { "<cmd>GHSubmitReview<cr>", "Submit" },
							z = { "<cmd>GHCollapseReview<cr>", "Collapse" },
						},
						p = {
							name = "+Pull Request",
							c = { "<cmd>GHClosePR<cr>", "Close" },
							d = { "<cmd>GHPRDetails<cr>", "Details" },
							e = { "<cmd>GHExpandPR<cr>", "Expand" },
							o = { "<cmd>GHOpenPR<cr>", "Open" },
							p = { "<cmd>GHPopOutPR<cr>", "PopOut" },
							r = { "<cmd>GHRefreshPR<cr>", "Refresh" },
							t = { "<cmd>GHOpenToPR<cr>", "Open To" },
							z = { "<cmd>GHCollapsePR<cr>", "Collapse" },
						},
						t = {
							name = "+Threads",
							c = { "<cmd>GHCreateThread<cr>", "Create" },
							n = { "<cmd>GHNextThread<cr>", "Next" },
							t = { "<cmd>GHToggleThread<cr>", "Toggle" },
						},
					},
				},
			}, { prefix = "<leader>" })
		end,
		lazy = false,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		lazy = false,
	},
	{
		"nvim-telescope/telescope.nvim",
		config = function()
			require("custom.configs.telescope")
		end,
	},
	{
		"nvim-tree/nvim-tree.lua",
		opts = function()
			return require("custom.configs.nvimtree")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function()
			return require("custom.configs.treesitter")
		end,
	},
	{
		"epwalsh/obsidian.nvim",
		lazy = true,
		event = {
			"BufReadPre /home/martinvysnovsky/Obsidian/**.md",
			"BufNewFile /home/martinvysnovsky/Obsidian/**.md",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = {
			dir = "~/Obsidian",
			mappings = {},
			daily_notes = {
				folder = "Daily",
				template = "Daily notes.md",
			},
			templates = {
				subdir = "Templates",
			},
			disable_frontmatter = true,
			completion = {
				new_notes_location = "notes_subdir",
				prepend_note_id = false,
			},
			note_id_func = function(title)
				return title
			end,
		},
	},
	{
		"tpope/vim-obsession",
		lazy = false,
	},
	{
		"barreiroleo/ltex-extra.nvim",
		lazy = false,
	},
	{
		"TamaMcGlinn/quickfixdd",
		lazy = false,
	},
}

return plugins
