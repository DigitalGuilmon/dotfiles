-- =================================================================
-- 🧠 ATAJOS LSP (Navegación, acciones y ayuda contextual)
-- =================================================================
local u = require("config.utils")
local m = u.m
local map = u.map


m["l"] = {
  name = "LSP",
  a = { vim.lsp.buf.code_action,      "Code Actions" },
  d = { vim.lsp.buf.definition,       "Ir a Definición" },
  D = { vim.lsp.buf.declaration,      "Ir a Declaración" },
  h = { vim.lsp.buf.hover,            "Hover / Documentación" },
  i = { vim.lsp.buf.implementation,   "Ir a Implementación" },
  r = { vim.lsp.buf.rename,           "Renombrar Símbolo" },
  R = { vim.lsp.buf.references,       "Referencias" },
  s = { vim.lsp.buf.signature_help,   "Ayuda de Firma" },
  t = { vim.lsp.buf.type_definition,  "Ir a Definición de Tipo" },
}

u.wk_extend_v("l", {
  name = "LSP",
  a = { vim.lsp.buf.code_action, "Code Actions" },
})


-- Atajos clásicos para mantener el flujo sin abrir which-key.
map("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover / Documentación" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Ir a Definición" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Ir a Declaración" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Ir a Implementación" })
map("n", "gr", vim.lsp.buf.references, { desc = "Referencias LSP" })
