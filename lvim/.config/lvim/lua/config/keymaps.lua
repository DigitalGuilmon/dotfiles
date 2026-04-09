-- =================================================================
-- ⌨️ KEYBINDINGS Y WHICH-KEY
-- =================================================================
local m = lvim.builtin.which_key.mappings
local map = vim.keymap.set


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
  d = { "<cmd>ObsidianToday<cr>", "Nota Diaria (Hoy)" },
  b = { "<cmd>ObsidianBacklinks<cr>", "Ver Backlinks" },
  f = { "<cmd>ObsidianFollowLink<cr>", "Seguir Enlace Bajo el Cursor" },
}

-- ⚙️ TOGGLES Y UI
m["t"] = {
  name = "Toggles",
  l = { function()
    local current = vim.diagnostic.config().virtual_lines
    vim.diagnostic.config({ virtual_lines = not current })
  end, "LSP Lines" },
  z = { function() Snacks.zen() end, "Modo Zen" },
  w = { "<cmd>set wrap!<cr>", "Word Wrap" },
  r = { "<cmd>set relativenumber!<cr>", "Números Relativos" },
  n = { "<cmd>set number!<cr>", "Números de Línea" },
  c = { "<cmd>ColorizerToggle<cr>", "Colorizer (Colores CSS)" },
  t = { "<cmd>TransparentToggle<cr>", "Transparencia" },
  s = { "<cmd>set spell!<cr>", "Corrector Ortográfico" },
  i = { function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, "Inlay Hints (LSP)" },
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

-- 🔀 Git Avanzado (Diffview + Gitsigns)
m["g"] = vim.tbl_deep_extend("force", m["g"] or { name = "Git" }, {
  v = { "<cmd>DiffviewOpen<cr>", "Abrir Diffview (3-way merge)" },
  h = { "<cmd>DiffviewFileHistory %<cr>", "Historial del Archivo Actual" },
  x = { "<cmd>DiffviewClose<cr>", "Cerrar Diffview" },
  g = { function() Snacks.lazygit() end, "Abrir Lazygit" },
  l = { function() Snacks.lazygit.log() end, "Git Log (Lazygit)" },
  s = { "<cmd>Gitsigns stage_hunk<cr>", "Stage Hunk" },
  r = { "<cmd>Gitsigns reset_hunk<cr>", "Reset Hunk" },
  S = { "<cmd>Gitsigns stage_buffer<cr>", "Stage Buffer Completo" },
  R = { "<cmd>Gitsigns reset_buffer<cr>", "Reset Buffer Completo" },
  u = { "<cmd>Gitsigns undo_stage_hunk<cr>", "Deshacer Stage Hunk" },
  p = { "<cmd>Gitsigns preview_hunk<cr>", "Preview Hunk (Flotante)" },
  B = { "<cmd>Gitsigns blame_line<cr>", "Blame Línea Actual" },
  D = { "<cmd>Gitsigns diffthis<cr>", "Diff Archivo Actual" },
})

-- 🚨 Trouble (Diagnósticos Avanzados)
m["x"] = {
  name = "Trouble (Diagnósticos)",
  x = { "<cmd>Trouble diagnostics toggle<cr>", "Diagnósticos del Proyecto" },
  X = { "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Diagnósticos (Buffer Actual)" },
  q = { "<cmd>Trouble qflist toggle<cr>", "Quickfix List" },
  l = { "<cmd>Trouble loclist toggle<cr>", "Location List" },
  r = { "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "Referencias LSP" },
  t = { "<cmd>Trouble todo toggle<cr>", "Ver TODOs del Proyecto" },
  T = { "<cmd>Trouble todo toggle filter.buf=0<cr>", "Ver TODOs (Buffer Actual)" },
}


-- =================================================================
-- 🧩 MAPEOS COMPLEMENTARIOS DE PLUGINS
-- =================================================================

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


-- =================================================================
-- 🪟 GESTIÓN DE VENTANAS (<leader>w)
-- =================================================================
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


-- =================================================================
-- 📑 GESTIÓN DE BUFFERS Y TABS (<leader>b)
-- =================================================================
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


-- =================================================================
-- ⚡ KEYMAPS DIRECTOS DE PRODUCTIVIDAD (Sin <leader>)
-- =================================================================

-- 🔄 Navegación Rápida entre Buffers
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Buffer Anterior" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Siguiente Buffer" })

-- 🪟 Redimensionar Ventanas con Ctrl+Flechas
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Aumentar Alto Ventana" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Reducir Alto Ventana" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Reducir Ancho Ventana" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Aumentar Ancho Ventana" })

-- 📐 Mover Líneas con Alt+j/k (Normal e Insert)
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Mover Línea Abajo" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Mover Línea Arriba" })
map("i", "<A-j>", "<Esc><cmd>m .+1<cr>==gi", { desc = "Mover Línea Abajo" })
map("i", "<A-k>", "<Esc><cmd>m .-2<cr>==gi", { desc = "Mover Línea Arriba" })

-- 💾 Guardado Rápido
map("n", "<C-s>", "<cmd>w<cr>", { desc = "Guardar Archivo" })
map("i", "<C-s>", "<Esc><cmd>w<cr>gi", { desc = "Guardar Archivo" })

-- 🎯 Flash.nvim: Treesitter Select (complementa el 's' ya mapeado)
map("n", "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
map("x", "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
map("o", "r", function() require("flash").remote() end, { desc = "Flash Remote" })

-- 🩺 LINTERS Y DIAGNÓSTICOS (Navegación Rápida Estilo 2026)
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Siguiente Diagnóstico" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Diagnóstico Anterior" })
map("n", "gl", vim.diagnostic.open_float, { desc = "Ver Diagnóstico Flotante" })

-- 🔀 Navegación de Hunks Git con ] y [
map("n", "]h", "<cmd>Gitsigns next_hunk<cr>", { desc = "Siguiente Hunk Git" })
map("n", "[h", "<cmd>Gitsigns prev_hunk<cr>", { desc = "Hunk Git Anterior" })

-- 📋 Mejor Manejo del Portapapeles
map("x", "p", '"_dP', { desc = "Pegar sin Perder Registro" })

-- 🔲 Mantener Selección al Indentar
map("v", "<", "<gv", { desc = "Desindentar y Mantener Selección" })
map("v", ">", ">gv", { desc = "Indentar y Mantener Selección" })

-- 📐 Mover Selección Visual con Alt+j/k
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Mover Selección Abajo" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Mover Selección Arriba" })

-- 🧭 Centrar al Navegar (Productividad)
map("n", "<C-d>", "<C-d>zz", { desc = "Media Página Abajo (Centrado)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Media Página Arriba (Centrado)" })
map("n", "n", "nzzzv", { desc = "Siguiente Búsqueda (Centrado)" })
map("n", "N", "Nzzzv", { desc = "Búsqueda Anterior (Centrado)" })


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

-- Git Hunk en Modo Visual (Seleccionar rango de líneas y operar)
vm["g"] = {
  name = "Git (Selección)",
  s = { "<cmd>Gitsigns stage_hunk<cr>", "Stage Hunk Seleccionado" },
  r = { "<cmd>Gitsigns reset_hunk<cr>", "Reset Hunk Seleccionado" },
}

-- Molten en Modo Visual (Evaluar selección exacta)
vm["M"] = {
  name = "Math & Jupyter (Molten)",
  e = { ":<C-u>MoltenEvaluateVisual<CR>gv", "Evaluar Selección" },
}
