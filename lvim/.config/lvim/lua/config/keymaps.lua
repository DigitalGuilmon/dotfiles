-- =================================================================
-- ⌨️ KEYBINDINGS Y WHICH-KEY
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
}

-- 🤖 INTELIGENCIA ARTIFICIAL
m["G"] = {
  name = "IA Gemini",
  c = { "<cmd>CodeCompanionChat Toggle<cr>", "Chat IA" },
  a = { "<cmd>CodeCompanionActions<cr>", "Acciones IA" },
  i = { "<cmd>CodeCompanion<cr>", "Prompt Inline" },
}

-- 📝 OBSIDIAN
m["o"] = {
  name = "Obsidian",
  n = { "<cmd>ObsidianNew<cr>", "Nueva Nota" },
  t = {
    function()
      local templates_dir = vim.fn.expand("~/vaults/personal/templates")
      require("snacks").picker.files({
        cwd = templates_dir,
        title = "Seleccionar Plantilla",
        confirm = function(picker, item)
          picker:close()
          vim.cmd("ObsidianTemplate " .. item.text)
        end,
      })
    end,
    "Insertar Plantilla"
  },
  s = {
    function() require("snacks").picker.files({ cwd = "~/vaults/personal" }) end,
    "Buscar en Vault"
  },
  l = { "<cmd>ObsidianLink<cr>", "Linkear Selección" },
}

-- ⚙️ TOGGLES Y UI
m["t"] = {
  name = "Toggles",
  l = { function()
    local current = vim.diagnostic.config().virtual_lines
    vim.diagnostic.config({ virtual_lines = not current })
  end, "LSP Lines" },
  z = { function() Snacks.zen() end, "Modo Zen" },
}

-- 🎓 ENTORNOS ESPECÍFICOS (Leetcode, LaTeX, Lean)
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

-- =================================================================
-- 💻 HERRAMIENTAS DE INGENIERÍA (Testing, DB, Git, HTTP)
-- =================================================================

-- 🛠️ Refactorización Rápida
m["j"] = { "<cmd>TSJToggle<cr>", "Join/Split Código (TreeSJ)" }

-- 🌐 Cliente HTTP (Kulala)
m["R"] = { "<cmd>lua require('kulala').run()<cr>", "Ejecutar Request HTTP" }

-- 🧪 Testing Integrado (Neotest)
m["T"] = {
  name = "Testing",
  t = { "<cmd>lua require('neotest').run.run()<cr>", "Ejecutar Test Cercano" },
  f = { "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", "Ejecutar Archivo Actual" },
  s = { "<cmd>lua require('neotest').summary.toggle()<cr>", "Panel de Resultados" },
  o = { "<cmd>lua require('neotest').output.open({ enter = true })<cr>", "Ver Output de Test" },
  x = { "<cmd>lua require('neotest').run.stop()<cr>", "Detener Test" },
}

-- 🗄️ Bases de Datos (Dadbod)
m["D"] = {
  name = "Database",
  u = { "<cmd>DBUIToggle<cr>", "Abrir/Cerrar Panel DB" },
  f = { "<cmd>DBUIFindBuffer<cr>", "Buscar Buffer DB" },
  a = { "<cmd>DBUIAddConnection<cr>", "Añadir Conexión" },
}

-- 🔀 Git Avanzado (Diffview)
-- Lo integramos dentro del menú "g" que LunarVim ya usa por defecto para Git
m["g"] = vim.tbl_deep_extend("force", m["g"] or { name = "Git" }, {
  v = { "<cmd>DiffviewOpen<cr>", "Abrir Diffview (3-way merge)" },
  h = { "<cmd>DiffviewFileHistory %<cr>", "Historial del Archivo Actual" },
  x = { "<cmd>DiffviewClose<cr>", "Cerrar Diffview" },
  g = { function() Snacks.lazygit() end, "Abrir Lazygit" },
  l = { function() Snacks.lazygit.log() end, "Git Log (Lazygit)" }
})

-- 🚨 Trouble (Diagnósticos Avanzados)
m["x"] = {
  name = "Trouble (Diagnósticos)",
  x = { "<cmd>Trouble diagnostics toggle<cr>", "Diagnósticos del Proyecto" },
  X = { "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Diagnósticos (Buffer Actual)" },
  q = { "<cmd>Trouble qflist toggle<cr>", "Quickfix List" },
  l = { "<cmd>Trouble loclist toggle<cr>", "Location List" },
  r = { "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "Referencias LSP" },
}


-- =================================================================
-- 🧩 MAPEOS FALTANTES (COMPLEMENTO)
-- =================================================================

-- 1. SESIONES DE SNACKS (Requerido por tu config: persistence = { enabled = true })
m["q"] = {
  name = "Sesiones (Snacks)",
  s = { function() Snacks.session.load() end, "Restaurar Sesión Actual" },
  l = { function() Snacks.session.load({ last = true }) end, "Restaurar Última Sesión" },
  d = { function() Snacks.session.delete() end, "Borrar Sesión" },
}

-- 2. LAZYGIT (Activaste lazygit en Snacks, pero no tenía tecla de acceso)
m["g"]["g"] = { function() Snacks.lazygit() end, "Abrir Lazygit" }
m["g"]["l"] = { function() Snacks.lazygit.log() end, "Git Log (Lazygit)" }

-- 3. TODO-COMMENTS (Instalado, pero sin forma de buscarlos. Lo enlazamos a Trouble)
m["x"]["t"] = { "<cmd>Trouble todo toggle<cr>", "Ver TODOs del Proyecto" }
m["x"]["T"] = { "<cmd>Trouble todo toggle filter.buf=0<cr>", "Ver TODOs (Buffer Actual)" }

-- 4. NOICE.NVIM (Necesario para limpiar mensajes flotantes que se queden pegados)
m["n"] = {
  name = "Noice UI",
  d = { "<cmd>Noice dismiss<cr>", "Ocultar Notificaciones" },
  h = { "<cmd>Noice history<cr>", "Historial de Mensajes" },
}

-- 5. OBSIDIAN (Faltan las notas diarias y navegación de enlaces)
m["o"]["d"] = { "<cmd>ObsidianToday<cr>", "Nota Diaria (Hoy)" }
m["o"]["b"] = { "<cmd>ObsidianBacklinks<cr>", "Ver Backlinks" }
m["o"]["f"] = { "<cmd>ObsidianFollowLink<cr>", "Seguir Enlace Bajo el Cursor" }


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


-- 🔬 EJECUCIÓN CIENTÍFICA (Molten / Jupyter)
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


-- 🩺 LINTERS Y DIAGNÓSTICOS (Navegación Rápida Estilo 2026)
vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Siguiente Diagnóstico" })
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Diagnóstico Anterior" })
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Ver Diagnóstico Flotante" })


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


-- Molten en Modo Visual (Evaluar selección exacta)
vm["M"] = {
  name = "Math & Jupyter (Molten)",
  e = { ":<C-u>MoltenEvaluateVisual<CR>gv", "Evaluar Selección" },
}

