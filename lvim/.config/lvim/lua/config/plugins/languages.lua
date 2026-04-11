local env = require("config.env")

local function mason_tools()
  local tools = {
    "prettier", "stylua", "eslint_d", "black", "ruff",
    "basedpyright", "typescript-language-server", "lua-language-server",
    "debugpy", "js-debug-adapter", "tailwindcss-language-server",
    "yaml-language-server", "json-lsp", "bash-language-server", "texlab",
    "taplo", "clangd", "rust-analyzer", "shellcheck", "shfmt",
    "luacheck", "markdownlint-cli2", "codelldb",
  }
  if env.go_toolchain_available() then
    table.insert(tools, "gopls")
    table.insert(tools, "delve")
  end
  return tools
end

return {
  {
    "mfussenegger/nvim-lint",
    config = function()
      require("config.lint").setup()
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function()
      return {
        run_on_start = false,
        ensure_installed = mason_tools(),
      }
    end,
  },
  { "Julian/lean.nvim", event = { "BufReadPre *.lean" }, opts = { lsp = {}, mappings = true } },
  {
    "kawre/leetcode.nvim",
    enabled = env.feature_enabled("challenge_tools"),
    build = ":TSUpdate html",
    cmd = "Leet",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
    },
    opts = {
      lang = "cpp",
      picker = { provider = "snacks-picker" },
      plugins = { non_standalone = true },
    },
  },
  {
    "lervag/vimtex",
    enabled = env.feature_enabled("latex_tools"),
    ft = { "tex", "plaintex", "bib" },
    init = function()
      local viewer = env.vimtex_view()
      vim.g.vimtex_view_method = viewer.method
      if viewer.viewer then
        vim.g.vimtex_view_general_viewer = viewer.viewer
      end
    end,
  },
  {
    "mechatroner/rainbow_csv",
    enabled = env.feature_enabled("csv_tools"),
    ft = { "csv", "tsv", "dat" },
    cmd = { "RainbowDelim", "RainbowDelimSimple", "RainbowAlign" },
  },
}
