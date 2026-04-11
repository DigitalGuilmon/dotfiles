local ai = require("config.ai")
local env = require("config.env")
local mode = require("config.mode")

local M = {}

function M.lines()
  local image_info = env.image_backend_info()
  local ai_scope = ai.current_scope()
  local spoon = env.spoon_lsp_status()
  local lines = {
    "Perfil activo: " .. (vim.env.LVIM_PROFILE or "personal"),
    "Perfil de maquina: " .. (vim.env.LVIM_MACHINE_PROFILE ~= nil and vim.env.LVIM_MACHINE_PROFILE ~= "" and vim.env.LVIM_MACHINE_PROFILE or "(ninguno)"),
    "AI: " .. table.concat(ai.status_lines(), " | "),
    "Persistencia AI: " .. ai_scope.kind .. " -> " .. ai_scope.name,
    "Archivo AI: " .. ai.state_path(),
    "Comandos AI: :LvimAIStatus :LvimAIProviders :LvimAISelectProvider :LvimAISelectModel :LvimAIReset",
    "Java/Spoon: " .. (spoon.enabled and ((spoon.ready and "listo via " .. spoon.kind) or ("pendiente - " .. spoon.reason)) or "deshabilitado"),
    "Imagenes/Molten: backend=" .. (image_info.backend or "none") .. " - " .. (image_info.reason or "sin detalles"),
    "tmux passthrough: " .. (env.tmux_allows_passthrough() and "on" or "off"),
    "Modo UI: " .. mode.current() .. " (" .. mode.scope_name() .. ")",
    "Comandos modo: :LvimModeIDE :LvimModeZen :LvimModeToggle :LvimModeStatus",
    "Workspace: :LvimWorkspaceIDE :LvimWorkspaceFocus :LvimWorkspaceTests :LvimWorkspaceDebug",
    "tmux IDE: <C-h/j/k/l> cruza splits+panes | :LvimTmuxShellBottom :LvimTmuxShellRight",
    "gopls bootstrap: " .. (env.go_toolchain_available() and "habilitado" or "omitido porque go no esta en PATH"),
    "Bootstrap: ./scripts/lvim-bootstrap.sh  |  Sanity: ./scripts/lvim-check.sh",
    "Health: :checkhealth lvim_ext",
  }
  return lines
end

vim.api.nvim_create_user_command("LvimSetupInfo", function()
  vim.notify(table.concat(M.lines(), "\n"), vim.log.levels.INFO, { title = "LVim Setup" })
end, {})

return M
