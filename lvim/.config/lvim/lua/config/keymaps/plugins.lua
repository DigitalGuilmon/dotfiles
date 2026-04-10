-- =================================================================
-- 🧩 MAPEOS COMPLEMENTARIOS DE PLUGINS
-- =================================================================
local m = require("config.utils").m


-- 📦 Undotree (Árbol de Deshacer Visual)
m["u"] = { "<cmd>UndotreeToggle<cr>", "Árbol de Deshacer (Undotree)" }

-- 1. SESIONES DE SNACKS (Requerido por tu config: persistence = { enabled = true })
m["q"] = {
  name = "Sesiones (Snacks)",
  s = { function() Snacks.session.load() end, "Restaurar Sesión Actual" },
  l = { function() Snacks.session.load({ last = true }) end, "Restaurar Última Sesión" },
  d = { function() Snacks.session.delete() end, "Borrar Sesión" },
}

-- 2. NOICE.NVIM (Necesario para limpiar mensajes flotantes que se queden pegados)
m["n"] = {
  name = "Noice UI",
  d = { "<cmd>Noice dismiss<cr>", "Ocultar Notificaciones" },
  h = { "<cmd>Noice history<cr>", "Historial de Mensajes" },
}


-- 🐞 DEBUGGING (DAP)
m["d"] = {
  name = "Debug (DAP)",
  t = { function() require("dap").toggle_breakpoint() end,  "Toggle Breakpoint" },
  b = { function() require("dap").step_back() end,          "Step Back" },
  c = { function() require("dap").continue() end,           "Continue" },
  C = { function() require("dap").run_to_cursor() end,      "Run To Cursor" },
  d = { function() require("dap").disconnect() end,         "Disconnect" },
  g = { function() require("dap").session() end,            "Get Session" },
  i = { function() require("dap").step_into() end,          "Step Into" },
  o = { function() require("dap").step_over() end,          "Step Over" },
  u = { function() require("dap").step_out() end,           "Step Out" },
  p = { function() require("dap").pause() end,              "Pause" },
  r = { function() require("dap").repl.toggle() end,        "Toggle Repl" },
  s = { function() require("dap").continue() end,           "Start" },
  q = { function() require("dap").close() end,              "Quit" },
  U = { function() require("dapui").toggle({ reset = true }) end, "Toggle UI DAP" },
}


-- 🧹 FORMATEO MANUAL
m["F"] = { function() require("lvim.core.formatters").format() end, "Formatear Archivo" }


-- 🍿 SNACKS (Terminal y Scratchpads)
m["S"] = {
  name = "Snacks Extras",
  s = { function() Snacks.scratch() end, "Toggle Scratchpad" },
  S = { function() Snacks.scratch.select() end, "Seleccionar Scratchpad" },
  t = { function() Snacks.terminal() end, "Terminal Flotante" },
}
