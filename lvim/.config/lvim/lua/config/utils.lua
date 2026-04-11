---@diagnostic disable: undefined-global
-- =================================================================
-- 🛠️ UTILIDADES COMPARTIDAS DE CONFIGURACIÓN
-- =================================================================

local M = {}

local function plugin_candidates(name)
  if type(name) ~= "string" or name == "" then
    return {}
  end

  local candidates = { name }
  local short = name:match(".*/([^/]+)$")
  if short and short ~= name then
    table.insert(candidates, short)
  end
  return candidates
end

local function has_plugin(name)
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if not (ok and lazy_config.plugins) then
    return false
  end

  for _, candidate in ipairs(plugin_candidates(name)) do
    if lazy_config.plugins[candidate] ~= nil then
      return true, candidate
    end
  end

  return false
end

local function ensure_which_key_tables()
  lvim.builtin.which_key = lvim.builtin.which_key or {}
  lvim.builtin.which_key.mappings = lvim.builtin.which_key.mappings or {}
  lvim.builtin.which_key.vmappings = lvim.builtin.which_key.vmappings or {}
  M.m = lvim.builtin.which_key.mappings
  M.vm = lvim.builtin.which_key.vmappings
  return M.m, M.vm
end

ensure_which_key_tables()

-- Alias de vim.keymap.set para reducir boilerplate
M.map = vim.keymap.set

local function run_rhs(rhs)
  local rhs_type = type(rhs)
  if rhs_type == "function" then
    return rhs()
  end
  if rhs_type == "string" then
    vim.api.nvim_feedkeys(vim.keycode(rhs), "m", false)
    return
  end
  error("Tipo de rhs no soportado para keymap: " .. rhs_type)
end

local function wk_target(target)
  local _, vm = ensure_which_key_tables()
  local m = M.m
  if target == "vm" then
    return vm
  end
  return m
end

function M.wk_assign(target, key, value)
  wk_target(target)[key] = value
end

function M.direct_map(mode, lhs, rhs, description, opts)
  local map_opts = vim.tbl_extend("force", { silent = true, desc = description }, opts or {})
  M.map(mode, lhs, rhs, map_opts)
end

function M.load_plugins(plugins)
  if not plugins or vim.tbl_isempty(plugins) then
    return true
  end

  local ok, lazy = pcall(require, "lazy")
  if not ok then
    return false
  end

  local load_targets = {}
  for _, plugin in ipairs(plugins) do
    local _, candidate = has_plugin(plugin)
    table.insert(load_targets, candidate or plugin)
  end

  lazy.load({ plugins = load_targets })

  for _, plugin in ipairs(plugins) do
    local found = has_plugin(plugin)
    if not found then
      return false, plugin
    end
  end

  return true
end

function M.lazy_wrap(plugins, rhs)
  if not plugins or vim.tbl_isempty(plugins) then
    return rhs
  end

  return function()
    local ok, missing_plugin = M.load_plugins(plugins)
    if not ok then
      vim.notify(("Plugin no disponible para esta configuración: %s"):format(missing_plugin or table.concat(plugins, ", ")), vim.log.levels.WARN)
      return
    end
    return run_rhs(rhs)
  end
end

function M.filetype_direct_map(pattern, mode, lhs, rhs, description, opts)
  local patterns = type(pattern) == "table" and pattern or { pattern }
  vim.api.nvim_create_autocmd("FileType", {
    pattern = patterns,
    callback = function(args)
      local map_opts = vim.tbl_extend("force", opts or {}, { buffer = args.buf })
      M.direct_map(mode, lhs, rhs, description, map_opts)
    end,
  })
end

-- Extiende (o crea) un grupo which-key en modo normal
function M.wk_extend(key, group)
  local m = wk_target("m")
  m[key] = vim.tbl_deep_extend("force", m[key] or {}, group)
end

-- Extiende (o crea) un grupo which-key en modo visual
function M.wk_extend_v(key, group)
  local vm = wk_target("vm")
  vm[key] = vim.tbl_deep_extend("force", vm[key] or {}, group)
end

return M
