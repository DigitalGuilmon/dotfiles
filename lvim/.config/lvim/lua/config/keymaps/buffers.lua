-- =================================================================
-- 📑 GESTIÓN DE BUFFERS Y TABS (<leader>b)
-- =================================================================
local m = lvim.builtin.which_key.mappings


m["b"] = vim.tbl_deep_extend("force", m["b"] or { name = "Buffers" }, {
  n = { "<cmd>BufferLineCycleNext<cr>", "Siguiente Buffer" },
  p = { "<cmd>BufferLineCyclePrev<cr>", "Buffer Anterior" },
  d = { "<cmd>BufferKill<cr>", "Cerrar Buffer Actual" },
  D = { "<cmd>BufferLineCloseOthers<cr>", "Cerrar Otros Buffers" },
  b = { "<cmd>lua Snacks.picker.buffers()<cr>", "Buscar Buffer" },
  e = { "<cmd>BufferLinePickClose<cr>", "Elegir Buffer a Cerrar" },
  P = { "<cmd>BufferLinePick<cr>", "Ir a Buffer (Pick)" },
  L = { "<cmd>BufferLineCloseRight<cr>", "Cerrar Buffers a la Derecha" },
  H = { "<cmd>BufferLineCloseLeft<cr>", "Cerrar Buffers a la Izquierda" },
  s = { "<cmd>BufferLineSortByDirectory<cr>", "Ordenar por Directorio" },
  l = { "<cmd>BufferLineSortByExtension<cr>", "Ordenar por Extensión" },
  ["1"] = { "<cmd>BufferLineGoToBuffer 1<cr>", "Ir a Buffer 1" },
  ["2"] = { "<cmd>BufferLineGoToBuffer 2<cr>", "Ir a Buffer 2" },
  ["3"] = { "<cmd>BufferLineGoToBuffer 3<cr>", "Ir a Buffer 3" },
  ["4"] = { "<cmd>BufferLineGoToBuffer 4<cr>", "Ir a Buffer 4" },
  ["5"] = { "<cmd>BufferLineGoToBuffer 5<cr>", "Ir a Buffer 5" },
})
