-- =================================================================
-- 👁️ MODO VISUAL (CRÍTICO PARA CODECOMPANION Y SNACKS)
-- =================================================================
local vm = lvim.builtin.which_key.vmappings


-- IA en Modo Visual: Seleccionas código y lo mandas directo a Gemini
vm["G"] = {
  name = "IA Gemini (Selección)",
  a = { "<cmd>CodeCompanionChat Add<cr>", "Añadir Código al Chat" },
  i = { "<cmd>CodeCompanion<cr>", "Modificar Selección (Inline)" },
}

-- Búsqueda en Modo Visual (Snacks)
vm["s"] = {
  name = "Search",
  g = { function() Snacks.picker.grep_word() end, "Buscar Selección (Grep)" },
}

-- Git Hunk en Modo Visual (Seleccionar rango de líneas y operar)
vm["g"] = {
  name = "Git (Selección)",
  s = { "<cmd>Gitsigns stage_hunk<cr>", "Stage Hunk Seleccionado" },
  r = { "<cmd>Gitsigns reset_hunk<cr>", "Reset Hunk Seleccionado" },
}

-- Molten en Modo Visual (Evaluar selección exacta)
vm["M"] = {
  name = "Math & Jupyter (Molten)",
  e = { ":<C-u>MoltenEvaluateVisual<CR>gv", "Evaluar Selección" },
}
