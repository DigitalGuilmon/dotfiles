---@diagnostic disable: undefined-global
-- =================================================================
-- 🛠️ UTILIDADES COMPARTIDAS DE CONFIGURACIÓN
-- =================================================================

local M = {}

-- Referencias directas a las tablas de which-key
M.m   = lvim.builtin.which_key.mappings
M.vm  = lvim.builtin.which_key.vmappings

-- Alias de vim.keymap.set para reducir boilerplate
M.map = vim.keymap.set

-- Extiende (o crea) un grupo which-key en modo normal
function M.wk_extend(key, group)
  M.m[key] = vim.tbl_deep_extend("force", M.m[key] or {}, group)
end

-- Extiende (o crea) un grupo which-key en modo visual
function M.wk_extend_v(key, group)
  M.vm[key] = vim.tbl_deep_extend("force", M.vm[key] or {}, group)
end

return M
