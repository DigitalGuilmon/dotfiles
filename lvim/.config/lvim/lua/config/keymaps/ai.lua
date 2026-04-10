-- =================================================================
-- 🤖 INTELIGENCIA ARTIFICIAL
-- =================================================================
local m = lvim.builtin.which_key.mappings


m["G"] = {
  name = "IA Gemini",
  c = { "<cmd>CodeCompanionChat Toggle<cr>", "Chat IA" },
  a = { "<cmd>CodeCompanionActions<cr>", "Acciones IA" },
  i = { "<cmd>CodeCompanion<cr>", "Prompt Inline" },
}
