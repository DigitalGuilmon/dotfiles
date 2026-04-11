---@diagnostic disable: undefined-global
-- -----------------------------------------------------------------------------
-- Generated from wm-shared/.config/wm-shared/keybinds.yml
-- Do not edit manually. Run ~/.config/wm-shared/scripts/bin/system/sync_keybinds.sh --target lvim
-- -----------------------------------------------------------------------------

local u = require("config.utils")
local m = u.m
local vm = u.vm
local map = u.map

-- =================================================================
-- 🤖 INTELIGENCIA ARTIFICIAL
-- =================================================================

u.wk_assign("m", "G", {
  name = "IA / LLM",
  c = { "<cmd>CodeCompanionChat Toggle<cr>", "Chat IA" },
  a = { "<cmd>CodeCompanionActions<cr>", "Acciones IA" },
  i = { "<cmd>CodeCompanion<cr>", "Prompt Inline" },
  s = { "<cmd>LvimAIStatus<cr>", "Estado IA" },
  h = { "<cmd>LvimSetupInfo<cr>", "Setup y Health" },
  p = { "<cmd>LvimAIProviders<cr>", "Ver Providers IA" },
  P = { "<cmd>LvimAISelectProvider<cr>", "Seleccionar Provider IA" },
  m = { "<cmd>LvimAISelectModel<cr>", "Seleccionar Modelo IA" },
  r = { "<cmd>LvimAIReset<cr>", "Reset Overrides IA" },
})

-- =================================================================
-- 📑 GESTIÓN DE BUFFERS Y TABS
-- =================================================================

u.wk_extend("b", {
  name = "Buffers",
  n = { "<cmd>BufferLineCycleNext<cr>", "Siguiente Buffer" },
  p = { "<cmd>BufferLineCyclePrev<cr>", "Buffer Anterior" },
  d = { "<cmd>BufferKill<cr>", "Cerrar Buffer Actual" },
  D = { "<cmd>BufferLineCloseOthers<cr>", "Cerrar Otros Buffers" },
  b = { function() Snacks.picker.buffers() end, "Buscar Buffer" },
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
-- 💻 HERRAMIENTAS DE INGENIERÍA
-- =================================================================

u.wk_assign("m", "j", { "<cmd>TSJToggle<cr>", "Join/Split Código (TreeSJ)" })

u.wk_assign("m", "R", { u.lazy_wrap({ "kulala.nvim" }, function() require("kulala").run() end), "Ejecutar Request HTTP" })

u.wk_assign("m", "T", {
  name = "Testing",
  t = { u.lazy_wrap({ "neotest" }, function() require("neotest").run.run() end), "Ejecutar Test Cercano" },
  f = { u.lazy_wrap({ "neotest" }, function() require("neotest").run.run(vim.fn.expand("%")) end), "Ejecutar Archivo Actual" },
  s = { u.lazy_wrap({ "neotest" }, function() require("neotest").summary.toggle() end), "Panel de Resultados" },
  o = { u.lazy_wrap({ "neotest" }, function() require("neotest").output.open({ enter = true }) end), "Ver Output de Test" },
  x = { u.lazy_wrap({ "neotest" }, function() require("neotest").run.stop() end), "Detener Test" },
  d = { u.lazy_wrap({ "neotest" }, function() require("neotest").run.run({ strategy = "dap" }) end), "Ejecutar Test con DAP" },
  c = { u.lazy_wrap({ "neotest" }, "<cmd>CoverageSummary<cr>"), "Resumen de Coverage" },
  v = { u.lazy_wrap({ "neotest" }, "<cmd>Coverage<cr>"), "Mostrar Coverage" },
  h = { u.lazy_wrap({ "neotest" }, "<cmd>CoverageHide<cr>"), "Ocultar Coverage" },
  R = { u.lazy_wrap({ "neotest" }, "<cmd>LvimCoverageRefresh<cr>"), "Recargar Coverage" },
})

u.wk_assign("m", "D", {
  name = "Database",
  u = { u.lazy_wrap({ "vim-dadbod-ui" }, "<cmd>DBUIToggle<cr>"), "Abrir/Cerrar Panel DB" },
  f = { u.lazy_wrap({ "vim-dadbod-ui" }, "<cmd>DBUIFindBuffer<cr>"), "Buscar Buffer DB" },
  a = { u.lazy_wrap({ "vim-dadbod-ui" }, "<cmd>DBUIAddConnection<cr>"), "Añadir Conexión" },
})

u.wk_extend("g", {
  name = "Git",
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

u.wk_assign("m", "x", {
  name = "Trouble (Diagnósticos)",
  x = { u.lazy_wrap({ "trouble.nvim" }, "<cmd>Trouble diagnostics toggle<cr>"), "Diagnósticos del Proyecto" },
  X = { u.lazy_wrap({ "trouble.nvim" }, "<cmd>Trouble diagnostics toggle filter.buf=0<cr>"), "Diagnósticos (Buffer Actual)" },
  q = { u.lazy_wrap({ "trouble.nvim" }, "<cmd>Trouble qflist toggle<cr>"), "Quickfix List" },
  l = { u.lazy_wrap({ "trouble.nvim" }, "<cmd>Trouble loclist toggle<cr>"), "Location List" },
  r = { u.lazy_wrap({ "trouble.nvim" }, "<cmd>Trouble lsp toggle focus=false win.position=right<cr>"), "Referencias LSP" },
  t = { u.lazy_wrap({ "trouble.nvim" }, "<cmd>Trouble todo toggle<cr>"), "Ver TODOs del Proyecto" },
  T = { u.lazy_wrap({ "trouble.nvim" }, "<cmd>Trouble todo toggle filter.buf=0<cr>"), "Ver TODOs (Buffer Actual)" },
})

-- =================================================================
-- 🎓 ENTORNOS ESPECÍFICOS
-- =================================================================

u.wk_assign("m", "C", {
  name = "LeetCode",
  c = { u.lazy_wrap({ "kawre/leetcode.nvim" }, "<cmd>Leet<cr>"), "Abrir Dashboard" },
  r = { u.lazy_wrap({ "kawre/leetcode.nvim" }, "<cmd>Leet run<cr>"), "Ejecutar Código (Run)" },
  s = { u.lazy_wrap({ "kawre/leetcode.nvim" }, "<cmd>Leet submit<cr>"), "Enviar Solución (Submit)" },
  l = { u.lazy_wrap({ "kawre/leetcode.nvim" }, "<cmd>Leet list<cr>"), "Lista de Problemas" },
  i = { u.lazy_wrap({ "kawre/leetcode.nvim" }, "<cmd>Leet info<cr>"), "Info del Problema" },
})

u.wk_assign("m", "L", {
  name = "LaTeX",
  c = { u.lazy_wrap({ "lervag/vimtex" }, "<cmd>VimtexCompile<cr>"), "Compilar (Start/Stop)" },
  v = { u.lazy_wrap({ "lervag/vimtex" }, "<cmd>VimtexView<cr>"), "Ver PDF" },
  e = { u.lazy_wrap({ "lervag/vimtex" }, "<cmd>VimtexErrors<cr>"), "Mostrar Errores" },
  t = { u.lazy_wrap({ "lervag/vimtex" }, "<cmd>VimtexTocOpen<cr>"), "Tabla de Contenidos" },
  x = { u.lazy_wrap({ "lervag/vimtex" }, "<cmd>VimtexClean<cr>"), "Limpiar Archivos Auxiliares" },
})

u.wk_assign("m", "i", { u.lazy_wrap({ "lean.nvim" }, "<cmd>LeanInfoviewToggle<cr>"), "Lean Infoview" })

-- =================================================================
-- 🧠 ATAJOS LSP
-- =================================================================

u.wk_assign("m", "l", {
  name = "LSP",
  a = { vim.lsp.buf.code_action, "Code Actions" },
  d = { vim.lsp.buf.definition, "Ir a Definición" },
  D = { vim.lsp.buf.declaration, "Ir a Declaración" },
  h = { vim.lsp.buf.hover, "Hover / Documentación" },
  i = { vim.lsp.buf.implementation, "Ir a Implementación" },
  r = { vim.lsp.buf.rename, "Renombrar Símbolo" },
  R = { vim.lsp.buf.references, "Referencias" },
  s = { vim.lsp.buf.signature_help, "Ayuda de Firma" },
  t = { vim.lsp.buf.type_definition, "Ir a Definición de Tipo" },
})

u.wk_extend_v("l", {
  name = "LSP",
  a = { vim.lsp.buf.code_action, "Code Actions" },
})

-- =================================================================
-- 🗺️ NAVEGACIÓN, ARCHIVOS Y BÚSQUEDA
-- =================================================================

u.wk_assign("m", "a", {
  name = "Aerial",
  t = { u.lazy_wrap({ "aerial.nvim" }, "<cmd>AerialToggle<cr>"), "Toggle Outline" },
  n = { u.lazy_wrap({ "aerial.nvim" }, "<cmd>AerialNavToggle<cr>"), "Toggle Nav" },
  j = { u.lazy_wrap({ "aerial.nvim" }, "<cmd>AerialNext<cr>"), "Siguiente Símbolo" },
  k = { u.lazy_wrap({ "aerial.nvim" }, "<cmd>AerialPrev<cr>"), "Símbolo Anterior" },
})

u.wk_assign("m", "e", { u.lazy_wrap({ "kelly-lin/ranger.nvim" }, function() require("ranger-nvim").open(true) end), "Explorador (Ranger)" })

u.wk_assign("m", "f", { "<cmd>lua Snacks.picker.smart()<cr>", "Smart Find" })

u.wk_assign("m", "s", {
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
  j = { u.lazy_wrap({ "flash.nvim" }, function() require("flash").jump() end), "Flash Jump" },
  t = { u.lazy_wrap({ "flash.nvim" }, function() require("flash").treesitter() end), "Flash Treesitter" },
  T = { u.lazy_wrap({ "flash.nvim" }, function() require("flash").treesitter_search() end), "Flash Treesitter Search" },
  m = { u.lazy_wrap({ "flash.nvim" }, function() require("flash").remote() end), "Flash Remote" },
})

-- =================================================================
-- 📝 OBSIDIAN
-- =================================================================

u.wk_assign("m", "o", {
  name = "Obsidian",
  n = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianNew<cr>"), "Nueva Nota" },
  q = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianQuickSwitch<cr>"), "Quick Switch" },
  S = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianSearch<cr>"), "Buscar Nota en Vault" },
  O = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianOpen<cr>"), "Abrir en App Obsidian" },
  w = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianWorkspace<cr>"), "Cambiar Workspace" },
  t = { u.lazy_wrap({ "obsidian.nvim" }, function()
  local templates_dir = require("config.env").obsidian_templates_dir()
  require("snacks").picker.files({
    cwd = templates_dir,
    title = "Seleccionar Plantilla",
    confirm = function(picker, item)
      picker:close()
      vim.cmd("ObsidianTemplate " .. item.text)
    end,
  })
end), "Insertar Plantilla" },
  s = { u.lazy_wrap({ "obsidian.nvim" }, function() require("snacks").picker.files({ cwd = require("config.env").obsidian_vault_dir() }) end), "Buscar en Vault" },
  l = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianLink<cr>"), "Linkear Selección" },
  L = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianLinks<cr>"), "Ver Links del Documento" },
  d = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianToday<cr>"), "Nota Diaria (Hoy)" },
  D = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianDailies<cr>"), "Explorar Diarias" },
  y = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianYesterday<cr>"), "Nota Diaria (Ayer)" },
  T = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianTomorrow<cr>"), "Nota Diaria (Mañana)" },
  G = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianTags<cr>"), "Explorar Tags" },
  b = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianBacklinks<cr>"), "Ver Backlinks" },
  f = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianFollowLink<cr>"), "Seguir Enlace Bajo el Cursor" },
  c = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianTOC<cr>"), "Tabla de Contenidos" },
  p = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianPasteImg<cr>"), "Pegar Imagen" },
  r = { u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianRename<cr>"), "Renombrar Nota" },
})

-- =================================================================
-- 🧩 PLUGINS Y SESIONES
-- =================================================================

u.wk_assign("m", "u", { "<cmd>UndotreeToggle<cr>", "Árbol de Deshacer (Undotree)" })

u.wk_assign("m", "q", {
  name = "Sesiones",
  s = { u.lazy_wrap({ "folke/persistence.nvim" }, "<cmd>LvimSessionSave<cr>"), "Guardar Sesión" },
  c = { u.lazy_wrap({ "folke/persistence.nvim" }, "<cmd>LvimSessionLoad<cr>"), "Restaurar Sesión Actual" },
  l = { u.lazy_wrap({ "folke/persistence.nvim" }, "<cmd>LvimSessionLast<cr>"), "Restaurar Última Sesión" },
  p = { u.lazy_wrap({ "folke/persistence.nvim" }, "<cmd>LvimSessionSelect<cr>"), "Seleccionar Sesión" },
  d = { u.lazy_wrap({ "folke/persistence.nvim" }, "<cmd>LvimSessionDelete<cr>"), "Borrar Sesión Actual" },
  x = { u.lazy_wrap({ "folke/persistence.nvim" }, "<cmd>LvimSessionStop<cr>"), "Detener Persistencia" },
})

u.wk_assign("m", "P", {
  name = "Workspace / tmux",
  i = { u.lazy_wrap({ "aerial.nvim", "trouble.nvim" }, "<cmd>LvimWorkspaceIDE<cr>"), "Layout IDE Completo" },
  w = { u.lazy_wrap({ "aerial.nvim", "trouble.nvim" }, function() require("config.workspace").focus_workspace() end), "Outline + Problemas" },
  t = { u.lazy_wrap({ "neotest" }, function() require("config.workspace").focus_testing() end), "Paneles de Tests" },
  d = { u.lazy_wrap({ "nvim-dap-ui" }, function() require("config.workspace").focus_debug() end), "Paneles de Debug" },
  x = { u.lazy_wrap({ "aerial.nvim", "trouble.nvim" }, "<cmd>LvimWorkspaceClose<cr>"), "Cerrar Paneles" },
  s = { function() require("config.tmux").project_shell("bottom") end, "Shell de Proyecto Abajo" },
  v = { function() require("config.tmux").project_shell("right") end, "Shell de Proyecto Derecha" },
})

u.wk_assign("m", "n", {
  name = "Noice UI",
  d = { u.lazy_wrap({ "noice.nvim" }, "<cmd>Noice dismiss<cr>"), "Ocultar Notificaciones" },
  h = { u.lazy_wrap({ "noice.nvim" }, "<cmd>Noice history<cr>"), "Historial de Mensajes" },
  l = { u.lazy_wrap({ "noice.nvim" }, "<cmd>Noice last<cr>"), "Último Mensaje" },
  e = { u.lazy_wrap({ "noice.nvim" }, "<cmd>Noice errors<cr>"), "Solo Errores" },
  a = { u.lazy_wrap({ "noice.nvim" }, "<cmd>Noice all<cr>"), "Todos los Mensajes" },
})

u.wk_assign("m", "d", {
  name = "Debug (DAP)",
  t = { function() require("dap").toggle_breakpoint() end, "Toggle Breakpoint" },
  b = { function() require("dap").step_back() end, "Step Back" },
  c = { function() require("dap").continue() end, "Continue" },
  C = { function() require("dap").run_to_cursor() end, "Run To Cursor" },
  d = { function() require("dap").disconnect() end, "Disconnect" },
  g = { function() require("dap").session() end, "Get Session" },
  i = { function() require("dap").step_into() end, "Step Into" },
  o = { function() require("dap").step_over() end, "Step Over" },
  u = { function() require("dap").step_out() end, "Step Out" },
  p = { function() require("dap").pause() end, "Pause" },
  r = { function() require("dap").repl.toggle() end, "Toggle Repl" },
  s = { function() require("dap").continue() end, "Start" },
  q = { function() require("dap").close() end, "Quit" },
  l = { u.lazy_wrap({ "nvim-dap-ui" }, "<cmd>LvimDapSelectConfig<cr>"), "Elegir Configuración" },
  R = { u.lazy_wrap({ "nvim-dap-ui" }, "<cmd>LvimDapRestart<cr>"), "Reiniciar Última Sesión" },
  U = { u.lazy_wrap({ "nvim-dap-ui" }, function() require("dapui").toggle({ reset = true }) end), "Toggle UI DAP" },
  e = { function() require("dapui").eval() end, "Evaluar Expresión" },
  w = { function() require("dapui").float_element("scopes", { enter = true }) end, "Scopes Flotantes" },
})

u.wk_assign("m", "F", { function() require("lvim.core.formatters").format() end, "Formatear Archivo" })

u.wk_assign("m", "K", { u.lazy_wrap({ "mfussenegger/nvim-lint" }, "<cmd>LvimLint<cr>"), "Lint Buffer Actual" })

u.wk_assign("m", "S", {
  name = "Snacks Extras",
  s = { function() Snacks.scratch() end, "Toggle Scratchpad" },
  S = { function() Snacks.scratch.select() end, "Seleccionar Scratchpad" },
  t = { function() Snacks.terminal() end, "Terminal Flotante" },
})

-- =================================================================
-- 📄 ACCIONES RÁPIDAS DE ARCHIVO
-- =================================================================

u.wk_assign("m", "v", {
  name = "Archivo Rápido",
  w = { "<cmd>w<cr>", "Guardar" },
  W = { "<cmd>wa<cr>", "Guardar Todo" },
  q = { "<cmd>confirm q<cr>", "Cerrar (Confirmar)" },
  Q = { "<cmd>qa!<cr>", "Forzar Salir de Todo" },
  x = { "<cmd>x<cr>", "Guardar y Cerrar" },
  a = { "<cmd>%y+<cr>", "Copiar Todo al Portapapeles" },
  n = { "<cmd>enew<cr>", "Nuevo Buffer Vacío" },
})

-- =================================================================
-- 🔬 EJECUCIÓN CIENTÍFICA
-- =================================================================

u.wk_assign("m", "M", {
  name = "Math & Jupyter (Molten)",
  i = { u.lazy_wrap({ "molten-nvim" }, "<cmd>MoltenInit<cr>"), "Iniciar Kernel (Python/R/Julia)" },
  e = { u.lazy_wrap({ "molten-nvim" }, "<cmd>MoltenEvaluateOperator<cr>"), "Evaluar Bloque/Operador" },
  l = { u.lazy_wrap({ "molten-nvim" }, "<cmd>MoltenEvaluateLine<cr>"), "Evaluar Línea" },
  r = { u.lazy_wrap({ "molten-nvim" }, "<cmd>MoltenReevaluateCell<cr>"), "Re-evaluar Celda" },
  d = { u.lazy_wrap({ "molten-nvim" }, "<cmd>MoltenDelete<cr>"), "Borrar Celda Visual" },
  h = { u.lazy_wrap({ "molten-nvim" }, "<cmd>MoltenHideOutput<cr>"), "Ocultar Output/Gráfico" },
})

u.wk_assign("m", "I", {
  name = "Interactive REPL (Iron)",
  r = { u.lazy_wrap({ "iron.nvim" }, "<cmd>IronRepl<cr>"), "Abrir REPL" },
  s = { u.lazy_wrap({ "iron.nvim" }, "<cmd>IronRestart<cr>"), "Reiniciar REPL" },
  f = { u.lazy_wrap({ "iron.nvim" }, "<cmd>IronFocus<cr>"), "Enfocar Ventana REPL" },
  h = { u.lazy_wrap({ "iron.nvim" }, "<cmd>IronHide<cr>"), "Ocultar REPL" },
})

-- =================================================================
-- 📊 TABLAS Y CSV
-- =================================================================

u.wk_assign("m", "Y", {
  name = "CSV / RBQL",
  d = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowDelim<cr>"), "Detectar Delimitador" },
  a = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowAlign<cr>"), "Alinear Columnas" },
  s = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowShrink<cr>"), "Limpiar Espaciado" },
  q = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowQuery<cr>"), "Consulta RBQL" },
  l = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>CSVLint<cr>"), "Validar CSV" },
  x = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>NoRainbowDelim<cr>"), "Desactivar Rainbow" },
  H = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowCellGoLeft<cr>"), "Celda Izquierda" },
  J = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowCellGoDown<cr>"), "Celda Abajo" },
  K = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowCellGoUp<cr>"), "Celda Arriba" },
  L = { u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowCellGoRight<cr>"), "Celda Derecha" },
})

-- =================================================================
-- ⚙️ TOGGLES Y UI
-- =================================================================

u.wk_assign("m", "t", {
  name = "Toggles",
  l = { function()
  local current = vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = not current })
end
, "LSP Lines" },
  b = { u.lazy_wrap({ "gitsigns.nvim" }, function()
  require("gitsigns").toggle_current_line_blame()
end
), "Git Blame Actual" },
  m = { u.lazy_wrap({ "MeanderingProgrammer/render-markdown.nvim" }, "<cmd>RenderMarkdown toggle<cr>"), "Render Markdown" },
  M = { u.lazy_wrap({ "MeanderingProgrammer/render-markdown.nvim" }, function()
  local enabled = vim.b.lvim_render_markdown_enabled
  if enabled == nil then
    enabled = true
  end
  enabled = not enabled
  vim.b.lvim_render_markdown_enabled = enabled
  vim.cmd("RenderMarkdown set_buf " .. tostring(enabled))
  local status = enabled and "activado" or "desactivado"
  vim.notify("Render Markdown del buffer " .. status, vim.log.levels.INFO)
end
), "Render Markdown Buffer" },
  a = { function()
  vim.g.lvim_notes_autosave_enabled = not vim.g.lvim_notes_autosave_enabled
  local status = vim.g.lvim_notes_autosave_enabled and "activado" or "desactivado"
  vim.notify("Autoguardado de notas " .. status, vim.log.levels.INFO)
end
, "Autoguardado Notas" },
  A = { function()
  vim.b.lvim_disable_notes_autosave = not vim.b.lvim_disable_notes_autosave
  local status = vim.b.lvim_disable_notes_autosave and "desactivado" or "activado"
  vim.notify("Autoguardado en este buffer " .. status, vim.log.levels.INFO)
end
, "Autoguardado Buffer" },
  f = { function()
  lvim.format_on_save.enabled = not lvim.format_on_save.enabled
  local status = lvim.format_on_save.enabled and "activado" or "desactivado"
  vim.notify("Format on save " .. status, vim.log.levels.INFO)
end
, "Format on Save" },
  d = { function()
  local config = vim.diagnostic.config()
  vim.diagnostic.config({ virtual_text = not config.virtual_text })
end
, "Diagnostic Text" },
  D = { function()
  local current = vim.diagnostic.config()
  local mode
  if current.virtual_lines and not current.virtual_text then
    vim.diagnostic.config({ virtual_lines = false, virtual_text = true })
    mode = "texto"
  elseif current.virtual_text then
    vim.diagnostic.config({ virtual_lines = false, virtual_text = false })
    mode = "minimal"
  else
    vim.diagnostic.config({ virtual_lines = { only_current_line = true }, virtual_text = false })
    mode = "lineas"
  end
  vim.notify("Diagnosticos en modo " .. mode, vim.log.levels.INFO)
end
, "Preset Diagnósticos" },
  z = { "<cmd>LvimModeToggle<cr>", "Alternar IDE / Zen" },
  I = { "<cmd>LvimModeIDE<cr>", "Activar Modo IDE" },
  Z = { "<cmd>LvimModeZen<cr>", "Activar Modo Zen" },
  w = { "<cmd>set wrap!<cr>", "Word Wrap" },
  r = { "<cmd>set relativenumber!<cr>", "Números Relativos" },
  n = { "<cmd>set number!<cr>", "Números de Línea" },
  c = { u.lazy_wrap({ "NvChad/nvim-colorizer.lua" }, "<cmd>ColorizerToggle<cr>"), "Colorizer (Colores CSS)" },
  t = { "<cmd>TransparentToggle<cr>", "Transparencia" },
  s = { "<cmd>set spell!<cr>", "Corrector Ortográfico" },
  i = { function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end
, "Inlay Hints (LSP)" },
})

-- =================================================================
-- 🪟 GESTIÓN DE VENTANAS
-- =================================================================

u.wk_assign("m", "w", {
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
})

-- =================================================================
-- 👁️ MODO VISUAL
-- =================================================================

u.wk_assign("vm", "G", {
  name = "IA / LLM (Selección)",
  a = { "<cmd>CodeCompanionChat Add<cr>", "Añadir Código al Chat" },
  i = { "<cmd>CodeCompanion<cr>", "Modificar Selección (Inline)" },
})

u.wk_assign("vm", "s", {
  name = "Search",
  g = { function() Snacks.picker.grep_word() end, "Buscar Selección (Grep)" },
})

u.wk_assign("vm", "g", {
  name = "Git (Selección)",
  s = { "<cmd>Gitsigns stage_hunk<cr>", "Stage Hunk Seleccionado" },
  r = { "<cmd>Gitsigns reset_hunk<cr>", "Reset Hunk Seleccionado" },
})

u.wk_assign("vm", "M", {
  name = "Math & Jupyter (Molten)",
  e = { u.lazy_wrap({ "molten-nvim" }, ":<C-u>MoltenEvaluateVisual<CR>gv"), "Evaluar Selección" },
})

-- =================================================================
-- ⚡ KEYMAPS DIRECTOS
-- =================================================================

u.direct_map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", "Buffer Anterior")

u.direct_map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", "Siguiente Buffer")

u.direct_map("n", "<C-Up>", "<cmd>resize +2<cr>", "Aumentar Alto Ventana")

u.direct_map("n", "<C-Down>", "<cmd>resize -2<cr>", "Reducir Alto Ventana")

u.direct_map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", "Reducir Ancho Ventana")

u.direct_map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", "Aumentar Ancho Ventana")

u.direct_map("n", "<A-j>", "<cmd>m .+1<cr>==", "Mover Línea Abajo")

u.direct_map("n", "<A-k>", "<cmd>m .-2<cr>==", "Mover Línea Arriba")

u.direct_map("i", "<A-j>", "<Esc><cmd>m .+1<cr>==gi", "Mover Línea Abajo")

u.direct_map("i", "<A-k>", "<Esc><cmd>m .-2<cr>==gi", "Mover Línea Arriba")

u.direct_map("n", "<C-s>", "<cmd>w<cr>", "Guardar Archivo")

u.direct_map("n", "<C-h>", function() require("config.tmux").navigate("left") end, "Navegar Izquierda (split/tmux)")

u.direct_map("n", "<C-j>", function() require("config.tmux").navigate("down") end, "Navegar Abajo (split/tmux)")

u.direct_map("n", "<C-k>", function() require("config.tmux").navigate("up") end, "Navegar Arriba (split/tmux)")

u.direct_map("n", "<C-l>", function() require("config.tmux").navigate("right") end, "Navegar Derecha (split/tmux)")

u.direct_map("t", "<C-h>", function() require("config.tmux").navigate("left") end, "Navegar Izquierda (split/tmux)")

u.direct_map("t", "<C-j>", function() require("config.tmux").navigate("down") end, "Navegar Abajo (split/tmux)")

u.direct_map("t", "<C-k>", function() require("config.tmux").navigate("up") end, "Navegar Arriba (split/tmux)")

u.direct_map("t", "<C-l>", function() require("config.tmux").navigate("right") end, "Navegar Derecha (split/tmux)")

u.direct_map("i", "<C-s>", "<Esc><cmd>w<cr>gi", "Guardar Archivo")

u.direct_map("n", "s", u.lazy_wrap({ "flash.nvim" }, function() require("flash").jump() end), "Flash")

u.direct_map("x", "s", u.lazy_wrap({ "flash.nvim" }, function() require("flash").jump() end), "Flash")

u.direct_map("o", "s", u.lazy_wrap({ "flash.nvim" }, function() require("flash").jump() end), "Flash")

u.direct_map("n", "S", u.lazy_wrap({ "flash.nvim" }, function() require("flash").treesitter() end), "Flash Treesitter")

u.direct_map("x", "S", u.lazy_wrap({ "flash.nvim" }, function() require("flash").treesitter() end), "Flash Treesitter")

u.direct_map("o", "r", u.lazy_wrap({ "flash.nvim" }, function() require("flash").remote() end), "Flash Remote")

u.direct_map("x", "R", u.lazy_wrap({ "flash.nvim" }, function() require("flash").treesitter_search() end), "Flash Treesitter Search")

u.direct_map("o", "R", u.lazy_wrap({ "flash.nvim" }, function() require("flash").treesitter_search() end), "Flash Treesitter Search")

u.direct_map("c", "<C-s>", u.lazy_wrap({ "flash.nvim" }, function() require("flash").toggle() end), "Toggle Flash Search")

u.direct_map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Siguiente Diagnóstico")

u.direct_map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Diagnóstico Anterior")

u.direct_map("n", "gl", vim.diagnostic.open_float, "Ver Diagnóstico Flotante")

u.direct_map("n", "]h", "<cmd>Gitsigns next_hunk<cr>", "Siguiente Hunk Git")

u.direct_map("n", "[h", "<cmd>Gitsigns prev_hunk<cr>", "Hunk Git Anterior")

u.direct_map("n", "]t", u.lazy_wrap({ "todo-comments.nvim" }, function() require("todo-comments").jump_next() end), "Siguiente TODO")

u.direct_map("n", "[t", u.lazy_wrap({ "todo-comments.nvim" }, function() require("todo-comments").jump_prev() end), "TODO Anterior")

u.direct_map("x", "p", "\"_dP", "Pegar sin Perder Registro")

u.direct_map("v", "<", "<gv", "Desindentar y Mantener Selección")

u.direct_map("v", ">", ">gv", "Indentar y Mantener Selección")

u.direct_map("v", "<A-j>", ":m '>+1<cr>gv=gv", "Mover Selección Abajo")

u.direct_map("v", "<A-k>", ":m '<-2<cr>gv=gv", "Mover Selección Arriba")

u.direct_map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Limpiar Resaltado de Búsqueda")

u.direct_map("n", "<C-a>", "ggVG", "Seleccionar Todo")

u.direct_map("n", "<C-q>", "<cmd>confirm q<cr>", "Cerrar (con confirmación)")

u.direct_map("v", "<C-c>", "\"+y", "Copiar al Portapapeles del Sistema")

u.direct_map("n", "<S-A-j>", "<cmd>t.<cr>", "Duplicar Línea Abajo")

u.direct_map("n", "<S-A-k>", "<cmd>t -1<cr>", "Duplicar Línea Arriba")

u.direct_map("i", "<S-A-j>", "<Esc><cmd>t.<cr>gi", "Duplicar Línea Abajo")

u.direct_map("i", "<S-A-k>", "<Esc><cmd>t -1<cr>gi", "Duplicar Línea Arriba")

u.direct_map("n", "<C-d>", "<C-d>zz", "Media Página Abajo (Centrado)")

u.direct_map("n", "<C-u>", "<C-u>zz", "Media Página Arriba (Centrado)")

u.direct_map("n", "n", "nzzzv", "Siguiente Búsqueda (Centrado)")

u.direct_map("n", "N", "Nzzzv", "Búsqueda Anterior (Centrado)")

u.direct_map("n", "K", vim.lsp.buf.hover, "LSP Hover / Documentación")

u.direct_map("n", "gd", vim.lsp.buf.definition, "Ir a Definición")

u.direct_map("n", "gD", vim.lsp.buf.declaration, "Ir a Declaración")

u.direct_map("n", "gi", vim.lsp.buf.implementation, "Ir a Implementación")

u.direct_map("n", "gr", vim.lsp.buf.references, "Referencias LSP")

u.filetype_direct_map("pdsl", "i", "<C-Space>", u.lazy_wrap({ "blink.cmp" }, function() require("config.pdsl").show_completion() end), "PDSL completion")
