-- =================================================================
-- 📦 PLUGINS (Ecosistema Refinado 2026)
-- =================================================================
lvim.plugins = {
  { "mbbill/undotree",                 cmd = "UndotreeToggle" },
  -- --- [ ESTÉTICA Y UI PREMIUM ] ---
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  { "giuxtaposition/blink-cmp-copilot" },
  {
    "marko-cerovac/material.nvim",
    priority = 1000,
    config = function()
      require('material').setup({
        lualine_style = "stealth",
        async_loading = true,
        custom_colors = function(colors) colors.editor.bg = "#0d1117" end,
      })
      vim.cmd.colorscheme("material")
    end
  },
  { "xiyaowong/transparent.nvim", opts = { extra_groups = { "NormalFloat", "NvimTreeNormal", "CursorLine", "FloatBorder" } } },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = { override = { ["vim.lsp.util.convert_input_to_markdown_lines"] = true, ["vim.lsp.util.stylize_markdown"] = true } },
      presets = { bottom_search = true, command_palette = true, long_message_to_split = true },
    },
  },
  { "stevearc/dressing.nvim",     opts = { input = { border = "rounded" } } },

  -- --- [ NAVEGACIÓN Y ESTRUCTURA ] ---
  { "SmiteshP/nvim-navic",        lazy = true },
  {
    "utilyre/barbecue.nvim",
    event = "LspAttach",
    dependencies = { "SmiteshP/nvim-navic", "nvim-tree/nvim-web-devicons" },
    opts = { theme = 'material', show_modified = true },
  },
  { "stevearc/oil.nvim",     opts = { columns = { "icon" }, float = { border = "rounded" } } },

  -- --- [ RENDIMIENTO M4: BLINK & SNACKS ] ---
  {
    "Saghen/blink.cmp",
    build = 'cargo build --release',
    opts = {
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = 'mono',
        kind_icons = {
          Copilot = "",
          CodeCompanion = "🤖",
          Text = "󰉿",
          Method = "󰊕",
          Function = "󰊕",
          Constructor = "󰒓",
          Field = "󰜢",
          Variable = "󰆦",
          Property = "󰖷",
          Class = "󱡠",
          Interface = "󱡠",
          Module = "󰅩",
          Snippet = "󱄽",
        },
      },
      keymap = {
        preset = 'enter',
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
      },
      -- 👇 MODIFICADO PARA SOPORTAR AUTOSNIPPETS MATEMÁTICOS 👇
      snippets = { preset = 'luasnip' },
      signature = { enabled = true, window = { border = "rounded" } },

      completion = {
        ghost_text = { enabled = true },
        menu = {
          border = "rounded",
          draw = {
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 }, { "source_name" } },
            components = {
              source_name = {
                text = function(ctx) return "[" .. ctx.source_name .. "]" end,
                highlight = "BlinkCmpSource",
              }
            }
          }
        },
        list = { selection = { preselect = true, auto_insert = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
      },

      fuzzy = {
        sorts = { "score", "sort_text" },
        prebuilt_binaries = { download = true },
      },

      cmdline = {
        enabled = true,
        sources = function()
          local type = vim.fn.getcmdtype()
          if type == '/' or type == '?' then return { 'buffer' } end
          if type == ':' then return { 'cmdline' } end
          return {}
        end,
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'codecompanion', 'copilot' },
        per_filetype = {
          env = { 'buffer', 'path' },
          markdown = { 'buffer', 'path', 'snippets' },
        },
        providers = {
          lsp = { fallbacks = { "buffer" } },
          copilot = { name = "Copilot", module = "blink-cmp-copilot", score_offset = 100, async = true },
          codecompanion = { name = "CodeCompanion", module = "codecompanion.providers.completion.blink", enabled = true, score_offset = 100, async = true },
          buffer = { score_offset = -10 },
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = { enabled = true },
      notifier = { enabled = false },
      input = { enabled = true },
      picker = { enabled = true, ui_select = true },
      indent = { enabled = true, char = "╎", scope = { enabled = true, char = "┃" } },
      scroll = { enabled = true },
      persistence = { enabled = true },
      lazygit = { enabled = true },
      zen = { enabled = true },
      terminal = { enabled = true },
      scratch = { enabled = true },
      image = { enabled = true },
    },
  },

  -- --- [ INTELIGENCIA ARTIFICIAL: CODECOMPANION ] ---
  {
    "olimorris/codecompanion.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("codecompanion").setup({
        adapters = {
          gemini = function()
            return require("codecompanion.adapters").extend("gemini", {
              env = { api_key = "GEMINI_API_KEY" },
            })
          end,
        },
        strategies = {
          chat = {
            adapter = "gemini",
            roles = {
              llm = "Ingeniero de Software Senior (M4 Optimized)",
              user = "Arquitecto de Sistemas",
            },
          },
          inline = { adapter = "gemini" }
        },
        display = { inline = { diff = { enabled = true, provider = "builtin" } } }
      })
    end,
  },

  -- --- [ NOTAS & RENDERING ] ---
  {
    "epwalsh/obsidian.nvim",
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = { { name = "personal", path = "~/vaults/personal" } },
      ui = { enabled = false },
      templates = { subdir = "templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
    }
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
    opts = {
      preset = "obsidian",
      checkbox = { enabled = true },
      latex = { enabled = true },
    },
  },

  -- --- [ LENGUAJES Y PORTABILIDAD ] ---
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettier", "stylua", "eslint_d", "black", "ruff",
          "pyright", "typescript-language-server", "lua-language-server",
        },
      })
    end,
  },
  { "Julian/lean.nvim",      event = { "BufReadPre *.lean" },                                                       opts = { lsp = {}, mappings = true } },
  { "kelly-lin/ranger.nvim", config = function() require("ranger-nvim").setup({ replace_netrw = true }) end },
  { "kawre/leetcode.nvim",   dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-telescope/telescope.nvim" }, opts = { lang = "cpp" } },
  {
    "lervag/vimtex",
    lazy = false,
    init = function() vim.g.vimtex_view_method = "zathura" end
  },

  -- --- [ CIENCIA DE DATOS Y MATEMÁTICAS ] ---
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
    end,
  },
  {
    "Vigemus/iron.nvim",
    config = function()
      require("iron.core").setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            sh = { command = { "zsh" } },
            python = { command = { "ipython" } },
          },
          repl_open_cmd = require("iron.view").split.vertical.botright(50),
        },
      })
    end,
  },
  {
    "mechatroner/rainbow_csv",
    ft = { "csv", "tsv", "dat" },
    cmd = { "RainbowDelim", "RainbowDelimSimple", "RainbowAlign" }
  },
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip").config.set_config({
        enable_autosnippets = true,
        update_events = "TextChanged,TextChangedI",
      })
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  -- --- [ INGENIERÍA Y EDICIÓN TÁCTICA ] ---
  {
    "echasnovski/mini.ai",
    version = false,
    config = function() require("mini.ai").setup() end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim", "antoinemadec/FixCursorHold.nvim" },
    config = function() require("neotest").setup({ adapters = {} }) end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { { "tpope/vim-dadbod", lazy = true }, { "kristijanhusak/vim-dadbod-completion", ft = { "sql" }, lazy = true } },
    cmd = { "DBUI", "DBUIToggle" },
  },
  { "mistweaverco/kulala.nvim", ft = "http",                                                  opts = {} },
  { "sindrets/diffview.nvim",   cmd = { "DiffviewOpen" } },
  { "Wansmer/treesj",           opts = { use_default_keymaps = false, max_join_length = 150 } },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = { modes = { char = { jump_labels = true } } },
    keys = { { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" }, },
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function() require("nvim-surround").setup() end
  },
  { "folke/trouble.nvim",                                 cmd = "Trouble",                                                    opts = {} },
  { "nvim-treesitter/nvim-treesitter-textobjects",        dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "theHamsta/nvim-dap-virtual-text",                    config = function() require("nvim-dap-virtual-text").setup() end },
  { "stevearc/aerial.nvim",                               opts = { attach_mode = "global" } },
  { "lewis6991/gitsigns.nvim",                            opts = { current_line_blame = true } },
  { "folke/todo-comments.nvim",                           opts = {} },
  { url = "https://git.sr.ht/~whynothugo/lsp_lines.nvim", config = function() require("lsp_lines").setup() end },

  -- --- [ COMPLEMENTOS FALTANTES ] ---
  { "rcarriga/nvim-dap-ui",                               dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
  {
    "echasnovski/mini.pairs",
    version = false,
    config = function() require("mini.pairs").setup() end
  },
  { "NvChad/nvim-colorizer.lua", opts = { user_default_options = { tailwind = true } } },
}



