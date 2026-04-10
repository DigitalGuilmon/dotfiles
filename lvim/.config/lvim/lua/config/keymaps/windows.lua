-- =================================================================
-- 🪟 GESTIÓN DE VENTANAS (<leader>w)
-- =================================================================
local m = lvim.builtin.which_key.mappings


m["w"] = {
  name = "Ventanas",
  s = { "<cmd>split<cr>", "Split Horizontal" },
  v = { "<cmd>vsplit<cr>", "Split Vertical" },
  c = { "<cmd>close<cr>", "Cerrar Ventana" },
  o = { "<cmd>only<cr>", "Cerrar Todas Menos Ésta" },
  ["="] = { "<C-w>=", "Igualar Tamaños" },
  m = { "<C-w>_<C-w>|", "Maximizar Ventana" },
  h = { "<C-w>H", "Mover Ventana a la Izquierda" },
  j = { "<C-w>J", "Mover Ventana Abajo" },
  k = { "<C-w>K", "Mover Ventana Arriba" },
  l = { "<C-w>L", "Mover Ventana a la Derecha" },
  r = { "<C-w>r", "Rotar Ventanas" },
  T = { "<C-w>T", "Ventana a Nueva Tab" },
  ["+"] = { "<cmd>resize +5<cr>", "Aumentar Alto" },
  ["-"] = { "<cmd>resize -5<cr>", "Reducir Alto" },
  [">"] = { "<cmd>vertical resize +5<cr>", "Aumentar Ancho" },
  ["<"] = { "<cmd>vertical resize -5<cr>", "Reducir Ancho" },
}
