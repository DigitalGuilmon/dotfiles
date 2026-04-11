---@diagnostic disable: undefined-global
-- =================================================================
-- 🚀 LUNARVIM 2026 - M4 ULTRA-OPTIMIZED (FULL STACK + AI + OBSIDIAN)
-- =================================================================

local env = require("config.env")

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
  conceallevel   = 0,
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
lvim.builtin.treesitter.auto_install = false

lvim.builtin.dap.active = true
lvim.format_on_save.enabled = true
lvim.format_on_save.timeout = 2000 -- Milisegundos que espera al formateador antes de guardar
lvim.lsp.installer.setup.automatic_installation = false
vim.g.lvim_notes_autosave_enabled = env.notes_autosave_enabled()
local notes_autosave_filetypes = env.notes_autosave_filetypes()
-- Fuerza a Mason a usar el Python de tu sistema
local python_path = env.preferred_python()
if python_path then
  lvim.builtin.mason.python_path = python_path
end


-- Guardado automático al perder el foco (Ideal para Obsidian y notas rápidas)
vim.api.nvim_create_autocmd({ "FocusLost", "WinLeave" }, {
  pattern = "*",
  callback = function(args)
    if not vim.g.lvim_notes_autosave_enabled then
      return
    end
    if vim.b[args.buf].lvim_disable_notes_autosave then
      return
    end
    if vim.bo[args.buf].buftype ~= "" or not vim.bo[args.buf].modifiable or vim.bo[args.buf].readonly then
      return
    end
    if not notes_autosave_filetypes[vim.bo[args.buf].filetype] then
      return
    end
    vim.api.nvim_buf_call(args.buf, function()
      vim.cmd("silent! update")
    end)
  end,
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
lvim.builtin.breadcrumbs.active = env.has_ui()

-- 3. DIAGNÓSTICOS (Optimizado para lsp_lines)
-- -----------------------------------------------------------------
vim.diagnostic.config({
  virtual_text  = false,
  virtual_lines = { only_current_line = true },
  underline     = true,
  severity_sort = true,
  float         = { border = "rounded", source = "if_many" },
})
