-- nvim-writing: a focused Markdown writing config
-- Launch with: NVIM_APPNAME=nvim-writing nvim

-- ── Core prose settings ──────────────────────────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Line wrapping for prose (soft wrap, no hard breaks)
opt.wrap = true
opt.linebreak = true -- wrap at word boundaries, not mid-word
opt.breakindent = true -- wrapped lines respect indentation
opt.showbreak = "  " -- subtle indent for wrapped lines

-- Spell check
opt.spell = true
opt.spelllang = { "en_gb" } -- British English

-- Visual comfort
opt.number = false -- no line numbers for prose
opt.relativenumber = false
opt.signcolumn = "no"
opt.cursorline = true
opt.scrolloff = 8 -- keep context above/below cursor
opt.sidescrolloff = 8

-- Sensible defaults
opt.mouse = "a"
opt.clipboard = "unnamedplus" -- system clipboard
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.conceallevel = 2 -- conceal Markdown syntax for cleaner reading
opt.textwidth = 0 -- don't hard-wrap
opt.wrapmargin = 0

-- Tabs as spaces (for Markdown indentation)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2

-- Minimal UI
opt.showmode = false
opt.ruler = false
opt.laststatus = 1 -- only show statusline if multiple windows
opt.cmdheight = 1

-- ── Bootstrap lazy.nvim ──────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ──────────────────────────────────────────────────────────
require("lazy").setup({
	-- Zen mode: centres text, hides distractions
	{
		"folke/zen-mode.nvim",
		opts = {
			window = {
				backdrop = 1,
				width = 72, -- comfortable prose column width
				options = {
					signcolumn = "no",
					number = false,
					relativenumber = false,
					cursorline = false,
					foldcolumn = "0",
				},
			},
			plugins = {
				twilight = { enabled = true },
				gitsigns = { enabled = false },
			},
		},
		keys = {
			{ "<leader>z", "<cmd>ZenMode<cr>", desc = "Toggle Zen Mode" },
		},
	},

	-- Twilight: dims inactive paragraphs
	{
		"folke/twilight.nvim",
		opts = {
			dimming = { alpha = 0.4 },
			context = 10,
			treesitter = true,
		},
	},

	-- Pencil: intelligent line wrapping for prose
	{
		"preservim/vim-pencil",
		ft = { "markdown", "text", "tex" },
		init = function()
			vim.g["pencil#wrapModeDefault"] = "soft"
			vim.g["pencil#textwidth"] = 72
			vim.g["pencil#conceallevel"] = 2
			vim.g["pencil#cursorwrap"] = 1
		end,
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "markdown", "text" },
				callback = function()
					vim.fn["pencil#init"]()
				end,
			})
		end,
	},

	-- Markdown rendering improvements
	{
		"lukas-reineke/headlines.nvim",
		ft = { "markdown" },
		dependencies = "nvim-treesitter/nvim-treesitter",
		config = function()
			require("headlines").setup({
				markdown = {
					headline_highlights = {
						"Headline1",
						"Headline2",
						"Headline3",
					},
					fat_headlines = false,
				},
			})
		end,
	},

	-- Treesitter for better syntax understanding
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "markdown" },
				callback = function()
					vim.treesitter.start()
				end,
			})
		end,
	},

	-- Clean, minimal colour scheme
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			theme = "wave",
			dimInactive = true,
			background = { dark = "wave", light = "lotus" },
		},
		config = function(_, opts)
			require("kanagawa").setup(opts)
			vim.cmd("colorscheme kanagawa")
		end,
	},

	-- Word count in statusline
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			options = {
				theme = "auto",
				component_separators = "",
				section_separators = "",
			},
			sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "filename", path = 1 } },
				lualine_x = {
					function()
						local wc = vim.fn.wordcount()
						local count = wc.visual_words or wc.words
						return count .. " words"
					end,
				},
				lualine_y = { "progress" },
				lualine_z = {},
			},
		},
	},
}, {
	-- lazy.nvim config
	install = { colorscheme = { "kanagawa" } },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
				"netrwPlugin",
			},
		},
	},
})

-- ── Keymaps ──────────────────────────────────────────────────────────
local map = vim.keymap.set

-- Navigation that respects soft wraps (j/k move visually, not by line)
map({ "n", "v" }, "j", "gj", { silent = true })
map({ "n", "v" }, "k", "gk", { silent = true })

-- Quick save
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })

-- Toggle spell suggestions
map("n", "z=", function()
	vim.ui.select(vim.fn.spellsuggest(vim.fn.expand("<cword>"), 10), { prompt = "Spell suggestion:" }, function(choice)
		if choice then
			vim.cmd("normal! ciw" .. choice)
		end
	end)
end, { desc = "Spell suggestions" })

-- Navigate spelling errors
map("n", "]s", "]s", { desc = "Next spelling error" })
map("n", "[s", "[s", { desc = "Previous spelling error" })

-- Add word to dictionary
map("n", "zg", "zg", { desc = "Add word to dictionary" })

-- Focus mode shortcut
map("n", "<leader>f", function()
	if pcall(require, "zen-mode") then
		require("zen-mode").toggle()
	end
end, { desc = "Focus mode" })

-- Quick new markdown file
map("n", "<leader>n", function()
	local name = vim.fn.input("New file: ", "", "file")
	if name ~= "" then
		if not name:match("%.md$") then
			name = name .. ".md"
		end
		vim.cmd("edit " .. name)
	end
end, { desc = "New Markdown file" })

-- ── Autocommands ─────────────────────────────────────────────────────

-- Auto-enter Zen Mode for Markdown files (waits for plugins to load)
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.defer_fn(function()
			if vim.bo.filetype == "markdown" and pcall(require, "zen-mode") then
				require("zen-mode").toggle()
			end
		end, 300)
	end,
})

-- Highlight customisation for headlines
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "Headline1", { fg = "#e6c384", bold = true })
		vim.api.nvim_set_hl(0, "Headline2", { fg = "#7aa89f", bold = true })
		vim.api.nvim_set_hl(0, "Headline3", { fg = "#957fb8", bold = true })
	end,
})
