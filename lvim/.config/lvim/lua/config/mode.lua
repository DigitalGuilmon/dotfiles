local env = require("config.env")

local M = {}

local state = {
  mode = "zen",
}

local function joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, "/")
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "LVim Mode" })
end

local function current_project_root()
  local cwd = vim.fn.getcwd()
  local root = env.project_root(cwd, {
    ".git",
    "package.json",
    "pyproject.toml",
    "go.mod",
    "Cargo.toml",
    "pom.xml",
    "settings.gradle",
    "lua",
  })
  if not root or root == "" then
    return nil
  end
  return vim.fs.normalize(root)
end

local function current_scope()
  local project_root = current_project_root()
  if project_root then
    return {
      kind = "project",
      name = project_root,
    }
  end

  local profile = vim.env.LVIM_PROFILE or "personal"
  local machine = vim.env.LVIM_MACHINE_PROFILE or "default-machine"
  return {
    kind = "profile",
    name = ("profile:%s|machine:%s"):format(profile, machine),
  }
end

local function state_dir()
  return joinpath(vim.fn.stdpath("state"), "lvim-ui-mode")
end

local function state_path_for(scope)
  local serialized = scope.kind .. "::" .. scope.name
  return joinpath(state_dir(), vim.fn.sha256(serialized) .. ".json")
end

local function write_state()
  vim.fn.mkdir(state_dir(), "p")
  local payload = vim.json.encode({
    mode = state.mode,
    scope = state.scope,
  })
  vim.fn.writefile(vim.split(payload, "\n", { plain = true }), state.path)
end

local function load_state_for_scope(scope)
  local path = state_path_for(scope)
  if vim.fn.filereadable(path) == 0 then
    return {
      mode = "zen",
      path = path,
      scope = scope,
    }
  end

  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if ok and type(decoded) == "table" and (decoded.mode == "ide" or decoded.mode == "zen") then
    return {
      mode = decoded.mode,
      path = path,
      scope = scope,
    }
  end

  return {
    mode = "zen",
    path = path,
    scope = scope,
  }
end

local function set_window_options(mode)
  local window_values = mode == "ide"
      and {
        number = true,
        relativenumber = true,
        cursorline = true,
        signcolumn = "yes",
        wrap = false,
      }
    or {
      number = false,
      relativenumber = false,
      cursorline = false,
      signcolumn = "no",
      wrap = false,
    }

  for key, value in pairs(window_values) do
    vim.opt[key] = value
  end

  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(winid)
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if config.relative == "" and vim.bo[bufnr].buftype == "" then
      local win = vim.wo[winid]
      win.number = window_values.number
      win.relativenumber = window_values.relativenumber
      win.cursorline = window_values.cursorline
      win.signcolumn = window_values.signcolumn
      win.wrap = window_values.wrap
    end
  end
end

local function set_inlay_hints(enabled)
  if not vim.lsp.inlay_hint or type(vim.lsp.inlay_hint.enable) ~= "function" then
    return
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "" then
      pcall(vim.lsp.inlay_hint.enable, enabled, { bufnr = bufnr })
    end
  end
end

local function set_indent_guides(enabled)
  local snacks = rawget(_G, "Snacks")
  if not snacks then
    return
  end

  local indent = package.loaded["snacks.indent"]
  if not indent then
    if vim.v.vim_did_enter == 0 then
      return
    end
    local ok
    ok, indent = pcall(function()
      return snacks.indent
    end)
    if not ok then
      return
    end
  end

  if enabled then
    pcall(indent.enable)
    return
  end

  pcall(indent.disable)
end

local function apply_diagnostics(mode)
  if mode == "ide" then
    vim.diagnostic.config({
      virtual_text = false,
      virtual_lines = true,
      underline = true,
      severity_sort = true,
      float = { border = "rounded", source = "if_many" },
    })
    return
  end

  vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = false,
    underline = false,
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
  })
end

local function apply_mode(mode)
  local workspace = require("config.workspace")

  vim.g.lvim_ui_mode = mode
  vim.opt.laststatus = mode == "ide" and 3 or 0
  vim.opt.showtabline = mode == "ide" and 2 or 0
  set_window_options(mode)
  apply_diagnostics(mode)
  set_inlay_hints(mode == "ide")
  set_indent_guides(mode == "ide")

  if mode == "zen" then
    vim.g.lvim_workspace_auto_opened = false
    workspace.close_all()
    return
  end

  vim.g.lvim_workspace_auto_opened = false
  if env.has_ui() and workspace.is_real_file_buffer(vim.api.nvim_get_current_buf()) then
    workspace.schedule_focus_ide(vim.api.nvim_get_current_buf(), 20)
  end
end

local function set_mode(mode, opts)
  opts = opts or {}
  if mode ~= "ide" and mode ~= "zen" then
    error("Modo no soportado: " .. tostring(mode))
  end

  state.mode = mode
  apply_mode(mode)
  if opts.persist ~= false then
    write_state()
  end
  if not opts.silent then
    notify(("Modo %s activado"):format(mode == "ide" and "IDE" or "Zen"))
  end
end

function M.current()
  return state.mode
end

function M.scope_name()
  local scope = state.scope or current_scope()
  return scope.kind .. " -> " .. scope.name
end

function M.restore()
  state = load_state_for_scope(current_scope())
  apply_mode(state.mode)
end

function M.set(mode)
  set_mode(mode)
end

function M.toggle()
  set_mode(M.current() == "ide" and "zen" or "ide")
end

vim.api.nvim_create_user_command("LvimModeIDE", function()
  M.set("ide")
end, {})

vim.api.nvim_create_user_command("LvimModeZen", function()
  M.set("zen")
end, {})

vim.api.nvim_create_user_command("LvimModeToggle", function()
  M.toggle()
end, {})

vim.api.nvim_create_user_command("LvimModeStatus", function()
  notify(("Modo actual: %s\nScope: %s"):format(M.current(), M.scope_name()))
end, {})

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("LvimModeScope", { clear = true }),
  callback = function()
    M.restore()
  end,
})

M.restore()

return M
