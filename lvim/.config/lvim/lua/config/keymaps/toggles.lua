-- =================================================================
-- ⚙️ TOGGLES Y UI
-- =================================================================
local m = lvim.builtin.which_key.mappings


m["t"] = {
  name = "Toggles",
  l = { function()
    local current = vim.diagnostic.config().virtual_lines
    vim.diagnostic.config({ virtual_lines = not current })
  end, "LSP Lines" },
  z = { function() Snacks.zen() end, "Modo Zen" },
  w = { "<cmd>set wrap!<cr>", "Word Wrap" },
  r = { "<cmd>set relativenumber!<cr>", "Números Relativos" },
  n = { "<cmd>set number!<cr>", "Números de Línea" },
  c = { "<cmd>ColorizerToggle<cr>", "Colorizer (Colores CSS)" },
  t = { "<cmd>TransparentToggle<cr>", "Transparencia" },
  s = { "<cmd>set spell!<cr>", "Corrector Ortográfico" },
  i = { function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, "Inlay Hints (LSP)" },
}
