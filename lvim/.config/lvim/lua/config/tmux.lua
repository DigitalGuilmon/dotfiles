local env = require("config.env")

local M = {}

local TMUX_PANE_FLAGS = {
  left = "-L",
  down = "-D",
  up = "-U",
  right = "-R",
}

local VIM_WINDOW_DIRECTIONS = {
  left = "h",
  down = "j",
  up = "k",
  right = "l",
}

local function in_tmux()
  return type(vim.env.TMUX) == "string" and vim.env.TMUX ~= ""
end

local function trim(text)
  return (text or ""):gsub("%s+$", "")
end

local function project_root()
  return env.project_root(vim.api.nvim_buf_get_name(0), {
    ".git",
    "pyproject.toml",
    "package.json",
    "Cargo.toml",
    "go.mod",
    "pom.xml",
    "build.gradle",
  })
end

local function shell_command()
  return env.preferred_shell()
end

local function run_system(command)
  local result = vim.system(command, { text = true }):wait()
  return result.code == 0, result
end

local function open_snacks_terminal()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    return false
  end
  snacks.terminal(nil, { cwd = project_root() })
  return true
end

local function split_args(direction)
  if direction == "right" then
    return { "-h", "-p", "40" }
  end
  return { "-v", "-p", "30" }
end

function M.in_tmux()
  return in_tmux()
end

function M.navigate(direction)
  local window_direction = VIM_WINDOW_DIRECTIONS[direction]
  if not window_direction then
    error("Direccion de navegacion no soportada: " .. tostring(direction))
  end

  local current = vim.fn.winnr()
  local target = vim.fn.winnr(window_direction)
  if target ~= current then
    vim.cmd("wincmd " .. window_direction)
    return true
  end

  if not in_tmux() then
    return false
  end

  local ok, result = run_system({ "tmux", "select-pane", TMUX_PANE_FLAGS[direction] })
  if not ok then
    vim.notify("No se pudo mover al pane tmux: " .. trim(result.stderr), vim.log.levels.WARN)
  end
  return ok
end

function M.project_shell(direction)
  local pane_direction = direction == "right" and "right" or "bottom"

  if not in_tmux() then
    if open_snacks_terminal() then
      return true
    end
    vim.notify("tmux no esta disponible para abrir un shell de proyecto.", vim.log.levels.WARN)
    return false
  end

  local command = {
    "tmux",
    "split-window",
    unpack(split_args(pane_direction)),
    "-c",
    project_root(),
    shell_command(),
  }
  local ok, result = run_system(command)
  if not ok then
    vim.notify("No se pudo abrir el shell de proyecto en tmux: " .. trim(result.stderr), vim.log.levels.WARN)
  end
  return ok
end

vim.api.nvim_create_user_command("LvimTmuxShellBottom", function()
  M.project_shell("bottom")
end, {})

vim.api.nvim_create_user_command("LvimTmuxShellRight", function()
  M.project_shell("right")
end, {})

return M
