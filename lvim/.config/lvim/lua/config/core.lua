---@diagnostic disable: undefined-global
-- =================================================================
-- 🚀 LUNARVIM 2026 - M4 ULTRA-OPTIMIZED (FULL STACK + AI + OBSIDIAN)
-- =================================================================

-- 0. OPTIMIZACIÓN DE ARRANQUE
vim.g.deprecation_warnings = false
if vim.loader then vim.loader.enable() end

-- 1. CONFIGURACIÓN DEL CORE
-- -----------------------------------------------------------------
vim.g.material_style = "deep ocean"

local undodir = vim.fn.expand("~/.local/state/nvim/undo")
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

-- Opciones de Vim (declarativo)
local vim_opts = {
  relativenumber = true,
  cursorline     = true,
  clipboard      = "unnamedplus",
  termguicolors  = true,
  conceallevel   = 2,     -- Oculta sintaxis Markdown para look Obsidian
  laststatus     = 3,     -- Barra de estado global única
  undodir        = undodir,
  undofile       = true,
  undolevels     = 10000,
}
for k, v in pairs(vim_opts) do vim.opt[k] = v end

vim.list_extend(lvim.builtin.treesitter.ensure_installed, {
  "html", "css", "javascript", "typescript", "tsx", "python", "lua",
  "markdown", "markdown_inline", "yaml", "json", "bash"
})

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
  virtual_text  = false,
  virtual_lines = { only_current_line = true },
  underline     = true,
  severity_sort = true,
  float         = { border = "rounded", source = "if_many" },
})
