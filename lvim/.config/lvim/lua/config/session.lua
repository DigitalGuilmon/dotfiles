local u = require("config.utils")

local M = {}
local group = vim.api.nvim_create_augroup("LvimSessionIntegration", { clear = true })

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "LVim Session" })
end

local function persistence()
  local ok, missing = u.load_plugins({ "folke/persistence.nvim" })
  if not ok then
    notify(("Plugin de sesiones no disponible: %s"):format(missing or "folke/persistence.nvim"), vim.log.levels.WARN)
    return nil
  end

  local loaded, plugin = pcall(require, "persistence")
  if not loaded then
    notify("No se pudo cargar persistence.nvim.", vim.log.levels.ERROR)
    return nil
  end

  return plugin
end

local function current_session_candidates(plugin)
  local files = {
    plugin.current(),
    plugin.current({ branch = false }),
  }
  local deduped, seen = {}, {}
  for _, file in ipairs(files) do
    if type(file) == "string" and file ~= "" and not seen[file] then
      seen[file] = true
      table.insert(deduped, file)
    end
  end
  return deduped
end

function M.save()
  local plugin = persistence()
  if not plugin then
    return
  end
  plugin.save()
  notify("Sesion guardada.")
end

function M.load_current()
  local plugin = persistence()
  if not plugin then
    return
  end
  plugin.load()
end

function M.load_last()
  local plugin = persistence()
  if not plugin then
    return
  end
  plugin.load({ last = true })
end

function M.select()
  local plugin = persistence()
  if not plugin then
    return
  end
  plugin.select()
end

function M.stop()
  local plugin = persistence()
  if not plugin then
    return
  end
  plugin.stop()
  notify("Persistencia de sesiones desactivada para esta instancia.")
end

function M.delete_current()
  local plugin = persistence()
  if not plugin then
    return
  end

  local deleted = false
  for _, file in ipairs(current_session_candidates(plugin)) do
    if vim.fn.filereadable(file) == 1 and vim.fn.delete(file) == 0 then
      deleted = true
    end
  end

  if deleted then
    notify("Sesion actual eliminada.")
    return
  end

  notify("No se encontro una sesion guardada para el contexto actual.", vim.log.levels.WARN)
end

local function register_commands()
  local commands = {
    LvimSessionSave = M.save,
    LvimSessionLoad = M.load_current,
    LvimSessionLast = M.load_last,
    LvimSessionSelect = M.select,
    LvimSessionDelete = M.delete_current,
    LvimSessionStop = M.stop,
  }

  for name, callback in pairs(commands) do
    if vim.fn.exists(":" .. name) ~= 2 then
      vim.api.nvim_create_user_command(name, callback, {})
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "PersistenceLoadPre",
  callback = function()
    local ok, workspace = pcall(require, "config.workspace")
    if ok then
      workspace.close_all()
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "PersistenceLoadPost",
  callback = function()
    local ok_mode, mode = pcall(require, "config.mode")
    if ok_mode then
      mode.restore()
    end

    local ok_workspace, workspace = pcall(require, "config.workspace")
    if ok_workspace then
      vim.schedule(function()
        workspace.schedule_focus_ide(vim.api.nvim_get_current_buf(), 20)
      end)
    end
  end,
})

register_commands()

return M
