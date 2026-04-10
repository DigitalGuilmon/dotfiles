-- =================================================================
-- 🎓 ENTORNOS ESPECÍFICOS (Leetcode, LaTeX, Lean)
-- =================================================================
local m = require("config.utils").m


-- LeetCode
m["C"] = {
  name = "LeetCode",
  c = { "<cmd>Leet<cr>", "Abrir Dashboard" },
  r = { "<cmd>Leet run<cr>", "Ejecutar Código (Run)" },
  s = { "<cmd>Leet submit<cr>", "Enviar Solución (Submit)" },
  l = { "<cmd>Leet list<cr>", "Lista de Problemas" },
  i = { "<cmd>Leet info<cr>", "Info del Problema" },
}

-- LaTeX (Vimtex)
m["L"] = {
  name = "LaTeX",
  c = { "<cmd>VimtexCompile<cr>", "Compilar (Start/Stop)" },
  v = { "<cmd>VimtexView<cr>", "Ver PDF" },
  e = { "<cmd>VimtexErrors<cr>", "Mostrar Errores" },
  t = { "<cmd>VimtexTocOpen<cr>", "Tabla de Contenidos" },
  x = { "<cmd>VimtexClean<cr>", "Limpiar Archivos Auxiliares" },
}

-- Lean 4 (Panel de información interactivo)
m["i"] = { "<cmd>LeanInfoviewToggle<cr>", "Lean Infoview" }
