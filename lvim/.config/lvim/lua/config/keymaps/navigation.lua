-- =================================================================
-- 🗺️📁🔍 NAVEGACIÓN, ARCHIVOS Y BÚSQUEDA
-- =================================================================
local m = lvim.builtin.which_key.mappings


-- 🗺️ Mapa del Código
m["a"] = { "<cmd>AerialToggle!<CR>", "Outline (Aerial)" }
-- 📁 NAVEGACIÓN Y ARCHIVOS DIRECTOS
m["e"] = { function() require("oil").toggle_float() end, "Explorador (Oil)" }
m["r"] = { function() require("ranger-nvim").open(true) end, "Ranger FM" }
m["f"] = { "<cmd>lua Snacks.picker.smart()<cr>", "Smart Find" }

-- 🔍 BÚSQUEDA AVANZADA (Snacks)
m["s"] = {
  name = "Search (Snacks)",
  f = { "<cmd>lua Snacks.picker.files()<cr>", "Archivos" },
  g = { "<cmd>lua Snacks.picker.grep()<cr>", "Grep (Texto)" },
  b = { "<cmd>lua Snacks.picker.buffers()<cr>", "Buffers Activos" },
  n = { "<cmd>lua Snacks.picker.notifications()<cr>", "Notificaciones" },
  h = { "<cmd>lua Snacks.picker.help()<cr>", "Help Tags" },
  c = { "<cmd>lua Snacks.picker.commands()<cr>", "Comandos" },
  k = { "<cmd>lua Snacks.picker.keymaps()<cr>", "Keymaps" },
  r = { "<cmd>lua Snacks.picker.recent()<cr>", "Archivos Recientes" },
  w = { "<cmd>lua Snacks.picker.grep_word()<cr>", "Palabra Bajo Cursor" },
  d = { "<cmd>lua Snacks.picker.diagnostics()<cr>", "Diagnósticos" },
  R = { "<cmd>lua Snacks.picker.resume()<cr>", "Reanudar Última Búsqueda" },
  s = { "<cmd>lua Snacks.picker.smart()<cr>", "Smart Find" },
  l = { "<cmd>lua Snacks.picker.lines()<cr>", "Líneas (Buffer Actual)" },
  ["/"] = { "<cmd>lua Snacks.picker.search_history()<cr>", "Historial de Búsqueda" },
}
