-- =================================================================
-- 🧩 MAPEOS COMPLEMENTARIOS DE PLUGINS
-- =================================================================
local m = lvim.builtin.which_key.mappings


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
  t = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
  b = { "<cmd>lua require'dap'.step_back()<cr>", "Step Back" },
  c = { "<cmd>lua require'dap'.continue()<cr>", "Continue" },
  C = { "<cmd>lua require'dap'.run_to_cursor()<cr>", "Run To Cursor" },
  d = { "<cmd>lua require'dap'.disconnect()<cr>", "Disconnect" },
  g = { "<cmd>lua require'dap'.session()<cr>", "Get Session" },
  i = { "<cmd>lua require'dap'.step_into()<cr>", "Step Into" },
  o = { "<cmd>lua require'dap'.step_over()<cr>", "Step Over" },
  u = { "<cmd>lua require'dap'.step_out()<cr>", "Step Out" },
  p = { "<cmd>lua require'dap'.pause()<cr>", "Pause" },
  r = { "<cmd>lua require'dap'.repl.toggle()<cr>", "Toggle Repl" },
  s = { "<cmd>lua require'dap'.continue()<cr>", "Start" },
  q = { "<cmd>lua require'dap'.close()<cr>", "Quit" },
  U = { "<cmd>lua require'dapui'.toggle({reset = true})<cr>", "Toggle UI DAP" },
}


-- 🧹 FORMATEO MANUAL
m["F"] = { "<cmd>lua require('lvim.core.formatters').format()<cr>", "Formatear Archivo" }


-- 🍿 SNACKS (Terminal y Scratchpads)
m["S"] = {
  name = "Snacks Extras",
  s = { function() Snacks.scratch() end, "Toggle Scratchpad" },
  S = { function() Snacks.scratch.select() end, "Seleccionar Scratchpad" },
  t = { function() Snacks.terminal() end, "Terminal Flotante" },
}
