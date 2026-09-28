return {
  -- A small set of genuinely different palettes. <leader>uC previews and
  -- persists a choice instead of rolling the dice on every startup.
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    opts = { style = "moon" },
  },
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    lazy = false,
    opts = { theme = "wave", background = { dark = "wave" } },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    lazy = false,
    opts = { variant = "moon" },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "macchiato",
      integrations = {
        gitsigns = true,
        which_key = true,
      },
    },
  },

  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false,
    opts = {
      terminal = { win = { position = "float", border = "rounded" } },
      input = { enabled = true },
      picker = { enabled = true },
      notifier = { enabled = true, timeout = 2500 },
      dashboard = {
        enabled = true,
        preset = {
          header = "NEOVIM",
          keys = {
            { icon = " ", key = "f", desc = "Find file", action = ":lua Snacks.picker.files()" },
            { icon = " ", key = "g", desc = "Find text", action = ":lua Snacks.picker.grep()" },
            { icon = " ", key = "r", desc = "Recent files", action = ":lua Snacks.picker.recent()" },
            { icon = " ", key = "n", desc = "New file", action = ":ene | startinsert" },
            { icon = "󰏘 ", key = "t", desc = "Pick theme", action = ":lua require('theme').pick()" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { icon = " ", title = "Actions", section = "keys", gap = 1, padding = 1 },
          { icon = " ", title = "Recent files", section = "recent_files", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "cmake",
        "go",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "rust",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
      { "<leader>e", "<cmd>Oil<cr>", desc = "File explorer" },
    },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
    },
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = false,
      current_line_blame_opts = { delay = 500 },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function bmap(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
        end
        bmap("]h", gs.next_hunk, "Next Git hunk")
        bmap("[h", gs.prev_hunk, "Previous Git hunk")
        bmap("<leader>hb", gs.toggle_current_line_blame, "Toggle Git blame")
        bmap("<leader>hp", gs.preview_hunk, "Preview Git hunk")
        bmap("<leader>hs", gs.stage_hunk, "Stage Git hunk")
        bmap("<leader>hr", gs.reset_hunk, "Reset Git hunk")
      end,
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunk" },
        { "<leader>u", group = "ui" },
        { "<leader>t", group = "terminal" },
      })
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
      },
    },
  },

  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format code",
      },
    },
    opts = {
      formatters_by_ft = { c = { "clang_format" }, cpp = { "clang_format" } },
    },
  },
}
