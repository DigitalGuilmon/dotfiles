local env = require("config.env")
local u = require("config.utils")

local M = {}
local auto_group = vim.api.nvim_create_augroup("LvimWorkspaceAutoOpen", { clear = true })
local layout_in_progress = false

local function is_real_file_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if vim.bo[bufnr].buftype ~= "" then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return false
  end

  return vim.bo[bufnr].filetype ~= "alpha"
end

local function ensure_plugins(plugins)
  local ok, missing = u.load_plugins(plugins)
  if ok then
    return true
  end
  vim.notify(("Plugin no disponible para esta accion: %s"):format(missing or table.concat(plugins, ", ")), vim.log.levels.WARN)
  return false
end

local function preserve_focus(fn)
  local current_win = vim.api.nvim_get_current_win()
  fn()
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
  end
end

function M.schedule_focus_ide(bufnr, delay)
  if not env.has_ui() or vim.g.lvim_ui_mode == "zen" or vim.g.lvim_workspace_auto_opened then
    return
  end

  if not is_real_file_buffer(bufnr) then
    return
  end

  vim.g.lvim_workspace_auto_opened = true
  vim.defer_fn(function()
    if is_real_file_buffer(bufnr) and vim.g.lvim_ui_mode == "ide" then
      local ok = M.focus_ide()
      if not ok then
        vim.g.lvim_workspace_auto_opened = false
      end
      return
    end
    vim.g.lvim_workspace_auto_opened = false
  end, delay or 80)
end

local function maybe_focus_workspace(args)
  M.schedule_focus_ide(args.buf)
end

function M.focus_workspace()
  if not env.has_ui() then
    return
  end

  if not ensure_plugins({ "stevearc/aerial.nvim", "folke/trouble.nvim" }) then
    return
  end

  local aerial = require("aerial")
  preserve_focus(function()
    if not aerial.is_open() then
      aerial.toggle({ focus = false, direction = "right" })
    end
  end)

  preserve_focus(function()
    M.focus_trouble()
  end)
end

function M.focus_trouble()
  if not env.has_ui() then
    return
  end

  if not ensure_plugins({ "folke/trouble.nvim" }) then
    return
  end

  preserve_focus(function()
    local ok, trouble = pcall(require, "trouble")
    if ok then
      trouble.open({
        mode = "diagnostics",
        focus = false,
        win = { position = "bottom" },
      })
    end
  end)
end

function M.close_workspace()
  local ok_aerial, aerial = pcall(require, "aerial")
  if ok_aerial then
    if aerial.nav_is_open() then
      aerial.nav_close()
    end
    aerial.close_all()
  end

  local ok_trouble, trouble = pcall(require, "trouble")
  if ok_trouble then
    pcall(trouble.close, "diagnostics")
  end
end

function M.focus_testing()
  if not env.has_ui() then
    return
  end

  if not ensure_plugins({ "nvim-neotest/neotest" }) then
    return
  end

  local neotest = require("neotest")
  preserve_focus(function()
    M.focus_workspace()
    neotest.summary.open()
    neotest.output_panel.open()
  end)
end

function M.focus_testing_summary()
  if not env.has_ui() then
    return
  end

  if not ensure_plugins({ "nvim-neotest/neotest" }) then
    return
  end

  local neotest = require("neotest")
  if neotest.summary and type(neotest.summary.open) == "function" then
    preserve_focus(function()
      neotest.summary.open()
    end)
  end
end

function M.close_testing()
  local ok, neotest = pcall(require, "neotest")
  if not ok then
    return
  end
 
  if neotest.summary and type(neotest.summary.close) == "function" then
    neotest.summary.close()
  end
  if neotest.output_panel and type(neotest.output_panel.close) == "function" then
    neotest.output_panel.close()
  end
end

function M.focus_debug()
  if not env.has_ui() then
    return
  end

  if not ensure_plugins({ "rcarriga/nvim-dap-ui" }) then
    return
  end

  preserve_focus(function()
    M.focus_workspace()
    require("dapui").open({ reset = true })
  end)
end

function M.focus_ide()
  if not env.has_ui() then
    return false
  end

  if not is_real_file_buffer(vim.api.nvim_get_current_buf()) then
    return false
  end

  if layout_in_progress then
    return false
  end

  layout_in_progress = true

  local ok, err = pcall(function()
    M.close_all()
    M.focus_testing_summary()
    M.focus_workspace()
    M.focus_trouble()

    local dap_ok, dap = pcall(require, "dap")
    if dap_ok and type(dap.session) == "function" and dap.session() then
      M.focus_debug()
    end
  end)

  layout_in_progress = false

  if not ok then
    vim.notify("No se pudo abrir el layout IDE: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.close_debug()
  local ok, dapui = pcall(require, "dapui")
  if ok then
    dapui.close()
  end
end

function M.close_all()
  M.close_testing()
  M.close_debug()
  M.close_workspace()
end

M.is_real_file_buffer = is_real_file_buffer

vim.api.nvim_create_user_command("LvimWorkspaceFocus", function()
  M.focus_workspace()
end, {})

vim.api.nvim_create_user_command("LvimWorkspaceTests", function()
  M.focus_testing()
end, {})

vim.api.nvim_create_user_command("LvimWorkspaceDebug", function()
  M.focus_debug()
end, {})

vim.api.nvim_create_user_command("LvimWorkspaceTrouble", function()
  M.focus_trouble()
end, {})

vim.api.nvim_create_user_command("LvimWorkspaceIDE", function()
  M.focus_ide()
end, {})

vim.api.nvim_create_user_command("LvimWorkspaceClose", function()
  M.close_all()
end, {})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = auto_group,
  callback = maybe_focus_workspace,
})

return M
