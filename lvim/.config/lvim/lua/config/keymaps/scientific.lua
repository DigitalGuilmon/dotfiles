-- =================================================================
-- 🔬 EJECUCIÓN CIENTÍFICA (Molten / Jupyter, Iron REPL)
-- =================================================================
local m = lvim.builtin.which_key.mappings


-- 🔬 Molten / Jupyter
m["M"] = {
  name = "Math & Jupyter (Molten)",
  i = { "<cmd>MoltenInit<cr>", "Iniciar Kernel (Python/R/Julia)" },
  e = { "<cmd>MoltenEvaluateOperator<cr>", "Evaluar Bloque/Operador" },
  l = { "<cmd>MoltenEvaluateLine<cr>", "Evaluar Línea" },
  r = { "<cmd>MoltenReevaluateCell<cr>", "Re-evaluar Celda" },
  d = { "<cmd>MoltenDelete<cr>", "Borrar Celda Visual" },
  h = { "<cmd>MoltenHideOutput<cr>", "Ocultar Output/Gráfico" },
}

-- 🔄 REPL INTERACTIVO (Iron)
m["I"] = {
  name = "Interactive REPL (Iron)",
  r = { "<cmd>IronRepl<cr>", "Abrir REPL" },
  s = { "<cmd>IronRestart<cr>", "Reiniciar REPL" },
  f = { "<cmd>IronFocus<cr>", "Enfocar Ventana REPL" },
  h = { "<cmd>IronHide<cr>", "Ocultar REPL" },
}
