-- =================================================================
-- 💻 HERRAMIENTAS DE INGENIERÍA (Testing, DB, Git, HTTP)
-- =================================================================
local u = require("config.utils")
local m = u.m


-- 🛠️ Refactorización Rápida
m["j"] = { "<cmd>TSJToggle<cr>", "Join/Split Código (TreeSJ)" }

-- 🌐 Cliente HTTP (Kulala)
m["R"] = { function() require("kulala").run() end, "Ejecutar Request HTTP" }

-- 🧪 Testing Integrado (Neotest)
m["T"] = {
  name = "Testing",
  t = { function() require("neotest").run.run() end,                       "Ejecutar Test Cercano" },
  f = { function() require("neotest").run.run(vim.fn.expand("%")) end,     "Ejecutar Archivo Actual" },
  s = { function() require("neotest").summary.toggle() end,                "Panel de Resultados" },
  o = { function() require("neotest").output.open({ enter = true }) end,   "Ver Output de Test" },
  x = { function() require("neotest").run.stop() end,                      "Detener Test" },
}

-- 🗄️ Bases de Datos (Dadbod)
m["D"] = {
  name = "Database",
  u = { "<cmd>DBUIToggle<cr>",       "Abrir/Cerrar Panel DB" },
  f = { "<cmd>DBUIFindBuffer<cr>",   "Buscar Buffer DB" },
  a = { "<cmd>DBUIAddConnection<cr>","Añadir Conexión" },
}

-- 🔀 Git Avanzado (Diffview + Gitsigns)
u.wk_extend("g", {
  name = "Git",
  v = { "<cmd>DiffviewOpen<cr>",                           "Abrir Diffview (3-way merge)" },
  h = { "<cmd>DiffviewFileHistory %<cr>",                  "Historial del Archivo Actual" },
  x = { "<cmd>DiffviewClose<cr>",                          "Cerrar Diffview" },
  g = { function() Snacks.lazygit() end,                   "Abrir Lazygit" },
  l = { function() Snacks.lazygit.log() end,               "Git Log (Lazygit)" },
  s = { "<cmd>Gitsigns stage_hunk<cr>",                    "Stage Hunk" },
  r = { "<cmd>Gitsigns reset_hunk<cr>",                    "Reset Hunk" },
  S = { "<cmd>Gitsigns stage_buffer<cr>",                  "Stage Buffer Completo" },
  R = { "<cmd>Gitsigns reset_buffer<cr>",                  "Reset Buffer Completo" },
  u = { "<cmd>Gitsigns undo_stage_hunk<cr>",               "Deshacer Stage Hunk" },
  p = { "<cmd>Gitsigns preview_hunk<cr>",                  "Preview Hunk (Flotante)" },
  B = { "<cmd>Gitsigns blame_line<cr>",                    "Blame Línea Actual" },
  D = { "<cmd>Gitsigns diffthis<cr>",                      "Diff Archivo Actual" },
})

-- 🚨 Trouble (Diagnósticos Avanzados)
m["x"] = {
  name = "Trouble (Diagnósticos)",
  x = { "<cmd>Trouble diagnostics toggle<cr>",                               "Diagnósticos del Proyecto" },
  X = { "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",                  "Diagnósticos (Buffer Actual)" },
  q = { "<cmd>Trouble qflist toggle<cr>",                                    "Quickfix List" },
  l = { "<cmd>Trouble loclist toggle<cr>",                                   "Location List" },
  r = { "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",        "Referencias LSP" },
  t = { "<cmd>Trouble todo toggle<cr>",                                      "Ver TODOs del Proyecto" },
  T = { "<cmd>Trouble todo toggle filter.buf=0<cr>",                         "Ver TODOs (Buffer Actual)" },
}
