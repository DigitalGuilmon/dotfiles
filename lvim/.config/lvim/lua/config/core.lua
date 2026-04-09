---@diagnostic disable: undefined-global
-- =================================================================
-- 🚀 LUNARVIM 2026 - M4 ULTRA-OPTIMIZED (FULL STACK + AI + OBSIDIAN)
-- =================================================================
-- Silenciar avisos de funciones obsoletas (Deprecation warnings)
-- Esto evitará que los popups de advertencia aparezcan al iniciar

-- Opcional: También puedes silenciar avisos específicos de la API si los anteriores persisten
vim.g.deprecation_warnings = false

-- 0. OPTIMIZACIÓN DE ARRANQUE
if vim.loader then vim.loader.enable() end

-- 1. CONFIGURACIÓN DEL CORE
-- -----------------------------------------------------------------
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.conceallevel = 2 -- Oculta sintaxis Markdown para look Obsidian
vim.opt.laststatus = 3   -- Barra de estado global única
vim.g.material_style = "deep ocean"
vim.list_extend(lvim.builtin.treesitter.ensure_installed, {
  "html", "css", "javascript", "typescript", "tsx", "python", "lua",
  "markdown", "markdown_inline", "yaml", "json", "bash"
})


local undodir = vim.fn.expand("~/.local/state/nvim/undo")
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir

vim.opt.undofile = true
vim.opt.undolevels = 10000
-- Directorio para que no ensucie tus carpetas de proyecto
vim.opt.undodir = vim.fn.expand("~/.local/state/nvim/undo")


lvim.builtin.dap.active = true
lvim.format_on_save.enabled = true
lvim.format_on_save.timeout = 2000 -- Milisegundos que espera al formateador antes de guardar
-- Fuerza a Mason a usar el Python de tu sistema
lvim.builtin.mason.python_path = "/opt/homebrew/bin/python3"


-- Guardado automático al perder el foco (Ideal para Obsidian y notas rápidas)
vim.api.nvim_create_autocmd({ "FocusLost", "WinLeave" }, {
  pattern = "*",
  command = "silent! update",
})

-- 2. DESACTIVAR BUILT-INS (Máximo Rendimiento)
-- -----------------------------------------------------------------
local disabled_builtins = {
  "illuminate", "indentlines", "terminal", "nvimtree",
  "cmp", "telescope", "alpha"
}
for _, builtin in ipairs(disabled_builtins) do
  lvim.builtin[builtin].active = false
end
lvim.builtin.breadcrumbs.active = true

-- 3. DIAGNÓSTICOS (Optimizado para lsp_lines)
-- -----------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { only_current_line = true },
  underline = true,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})


