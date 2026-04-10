-- =================================================================
-- 📄 ACCIONES RÁPIDAS DE ARCHIVO (<leader>v)
-- =================================================================
local m = lvim.builtin.which_key.mappings


m["v"] = {
  name = "Archivo Rápido",
  w = { "<cmd>w<cr>", "Guardar" },
  W = { "<cmd>wa<cr>", "Guardar Todo" },
  q = { "<cmd>confirm q<cr>", "Cerrar (Confirmar)" },
  Q = { "<cmd>qa!<cr>", "Forzar Salir de Todo" },
  x = { "<cmd>x<cr>", "Guardar y Cerrar" },
  a = { "<cmd>%y+<cr>", "Copiar Todo al Portapapeles" },
  n = { "<cmd>enew<cr>", "Nuevo Buffer Vacío" },
}
