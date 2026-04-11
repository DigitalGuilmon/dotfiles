local env = require("config.env")
local ai = require("config.ai")

local function copilot_completion_enabled()
  if vim.tbl_contains({ "gitcommit", "markdown", "text", "pdsl" }, vim.bo.filetype) then
    return false
  end

  local ok, client = pcall(require, "copilot.client")
  if not ok or client.is_disabled() then
    return false
  end

  client.ensure_client_started()
  client.buf_attach(false, 0)

  return client.get() ~= nil and client.buf_is_attached(0)
end

local function codecompanion_adapter(provider_name)
  local provider = env.ai_provider_spec(provider_name)
  if not provider then
    error(("Unsupported LVim AI provider '%s'"):format(provider_name))
  end

  local adapter_config = {}
  local api_key_env = env.ai_api_key_env(provider_name)
  if api_key_env and (not provider.native_api_key_fallback or env.ai_api_key_value(provider_name) or vim.env.LVIM_AI_API_KEY_ENV) then
    adapter_config.env = { api_key = api_key_env }
  end

  local model = env.ai_model(provider_name)
  if model then
    adapter_config.schema = { model = { default = model } }
  end

  return require("codecompanion.adapters").extend(provider.adapter, adapter_config)
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts_extend = { "filetypes" },
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = false,
        debounce = 75,
        keymap = {
          accept = "<Tab>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        gitcommit = false,
        markdown = false,
        text = false,
      },
    },
  },
  { "giuxtaposition/blink-cmp-copilot", dependencies = { "zbirenbaum/copilot.lua" } },
  {
    "Saghen/blink.cmp",
    version = "1.*",
    opts = function(_, opts)
      opts = opts or {}

      opts.appearance = vim.tbl_deep_extend("force", opts.appearance or {}, {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
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
      })

      opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
        preset = "enter",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
      })

      opts.snippets = vim.tbl_deep_extend("force", opts.snippets or {}, { preset = "luasnip" })
      opts.signature = vim.tbl_deep_extend("force", opts.signature or {}, { enabled = true, window = { border = "rounded" } })
      opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
        trigger = {
          prefetch_on_insert = true,
          show_on_insert = true,
          show_on_keyword = true,
          show_on_trigger_character = true,
        },
        ghost_text = { enabled = false },
        menu = {
          auto_show = true,
          border = "rounded",
          draw = {
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 }, { "source_name" } },
            components = {
              source_name = {
                text = function(ctx)
                  return "[" .. ctx.source_name .. "]"
                end,
                highlight = "BlinkCmpSource",
              },
            },
          },
        },
        list = { selection = { preselect = false, auto_insert = false } },
        documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
      })

      opts.fuzzy = vim.tbl_deep_extend("force", opts.fuzzy or {}, {
        sorts = { "score", "sort_text" },
        prebuilt_binaries = { download = true },
      })

      opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
        enabled = true,
        sources = function()
          local type = vim.fn.getcmdtype()
          if type == "/" or type == "?" then
            return { "buffer" }
          end
          if type == ":" then
            return { "cmdline" }
          end
          return {}
        end,
      })

      opts.sources = opts.sources or {}
      opts.sources.default = { "lsp", "snippets", "path", "buffer" }
      opts.sources.per_filetype = vim.tbl_deep_extend("force", opts.sources.per_filetype or {}, {
        env = { "buffer", "path" },
        gitcommit = { "buffer", "path", "snippets" },
        lua = { "lsp", "snippets", "path", "buffer", "copilot", "codecompanion" },
        markdown = { "buffer", "path", "snippets" },
        pdsl = { "lsp", "path", "snippets" },
        python = { "lsp", "snippets", "path", "buffer", "copilot", "codecompanion" },
        javascript = { "lsp", "snippets", "path", "buffer", "copilot", "codecompanion" },
        javascriptreact = { "lsp", "snippets", "path", "buffer", "copilot", "codecompanion" },
        text = { "buffer", "path", "snippets" },
        typescript = { "lsp", "snippets", "path", "buffer", "copilot", "codecompanion" },
        typescriptreact = { "lsp", "snippets", "path", "buffer", "copilot", "codecompanion" },
        yaml = { "lsp", "path", "snippets", "buffer" },
      })
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        lsp = { score_offset = 120 },
        path = { score_offset = 20 },
        snippets = { score_offset = 10 },
        copilot = {
          name = "Copilot",
          module = "lvim_ext.blink_copilot",
          score_offset = 60,
          async = true,
          enabled = copilot_completion_enabled,
        },
        codecompanion = {
          name = "CodeCompanion",
          module = "codecompanion.providers.completion.blink",
          enabled = function()
            return not vim.tbl_contains({ "gitcommit", "markdown", "text", "pdsl" }, vim.bo.filetype)
          end,
          score_offset = 40,
          async = true,
        },
        buffer = {
          score_offset = -100,
          enabled = function()
            return vim.bo.filetype ~= "pdsl"
          end,
        },
      })

      return opts
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("codecompanion").setup({
        adapters = {
          lvim_session = function()
            return ai.resolve_adapter()
          end,
          claude = function()
            return codecompanion_adapter("claude")
          end,
          gemini = function()
            return codecompanion_adapter("gemini")
          end,
          openai = function()
            return codecompanion_adapter("openai")
          end,
          xai = function()
            return codecompanion_adapter("xai")
          end,
          deepseek = function()
            return codecompanion_adapter("deepseek")
          end,
          githubmodels = function()
            return codecompanion_adapter("githubmodels")
          end,
        },
        strategies = {
          chat = {
            adapter = "lvim_session",
            roles = {
              llm = "Ingeniero de Software Senior (M4 Optimized)",
              user = "Arquitecto de Sistemas",
            },
          },
          inline = { adapter = "lvim_session" },
        },
        display = { inline = { diff = { enabled = true, provider = "builtin" } } },
      })
    end,
  },
}
