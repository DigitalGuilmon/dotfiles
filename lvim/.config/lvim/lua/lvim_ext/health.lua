local env = require("config.env")

local health = vim.health or require("health")

local M = {}

local function joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, "/")
end

local function current_script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then
    return vim.fn.fnamemodify(source:sub(2), ":p:h")
  end
  return vim.fn.getcwd()
end

local function find_upwards(relative_path)
  local dir = current_script_dir()
  while dir and dir ~= "" and dir ~= "/" do
    local candidate = joinpath(dir, relative_path)
    if vim.fn.filereadable(candidate) == 1 or vim.fn.isdirectory(candidate) == 1 then
      return candidate
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

function M.check()
  health.start("LVim profiles and commands")
  local ai = require("config.ai")
  if vim.fn.exists(":LvimSetupInfo") == 2 then
    health.ok("LvimSetupInfo command is available.")
  else
    health.error("LvimSetupInfo command is missing.")
  end
  if vim.fn.exists(":LvimAIStatus") == 2 then
    health.ok("AI control commands are registered.")
  else
    health.error("AI control commands are missing.")
  end
  health.info("LVIM_PROFILE=" .. (vim.env.LVIM_PROFILE or "personal"))
  health.info("LVIM_MACHINE_PROFILE=" .. ((vim.env.LVIM_MACHINE_PROFILE and vim.env.LVIM_MACHINE_PROFILE ~= "") and vim.env.LVIM_MACHINE_PROFILE or "(none)"))
  health.info("AI scope=" .. ai.current_scope().kind .. " -> " .. ai.current_scope().name)
  health.info("AI state file=" .. ai.state_path())

  health.start("LVim AI")
  local api_env = env.ai_api_key_env()
  if api_env and vim.env[api_env] and vim.env[api_env] ~= "" then
    health.ok("Current AI backend credentials found in " .. api_env .. ".")
  elseif api_env then
    health.warn("Current AI backend is missing " .. api_env .. ".", { "Set the environment variable before starting LVim." })
  else
    health.ok("Current AI backend uses plugin-managed credentials.")
  end

  health.start("LVim Java / Spoon")
  local spoon = env.spoon_lsp_status()
  if not spoon.enabled then
    health.info("Spoon LSP está deshabilitado para el perfil actual.")
  elseif spoon.ready then
    health.ok("Spoon LSP listo vía " .. spoon.kind .. ": " .. spoon.location)
  else
    health.warn("Spoon LSP habilitado pero no listo: " .. spoon.reason, {
      "Ejecuta ./scripts/lvim-prepare-spoon.sh o configura SPOON_JDT_LSP_JAR/SPOON_JDT_LSP_DIR.",
    })
  end
  if env.first_executable({ "mvn" }) then
    health.ok("Maven está disponible para builds de Spoon desde código fuente.")
  else
    health.warn("Maven no está instalado.", {
      "Instálalo si quieres preparar Spoon desde SPOON_JDT_LSP_DIR.",
    })
  end

  health.start("LVim Molten and image support")
  local image_info = env.image_backend_info()
  if image_info.backend then
    health.ok("Image backend selected: " .. image_info.backend)
  else
    health.warn(image_info.reason or "Image output is disabled.", {
      "Install ueberzugpp for tmux sessions, or enable tmux allow-passthrough when using Kitty graphics.",
    })
  end
  if vim.fn.executable("magick") == 1 or vim.fn.executable("convert") == 1 then
    health.ok("ImageMagick is available.")
  else
    health.warn("ImageMagick is not installed.", { "Install ImageMagick to render Molten and markdown images." })
  end
  if vim.env.TMUX then
    if env.tmux_allows_passthrough() then
      health.ok("tmux allow-passthrough is enabled.")
    else
      health.warn("tmux allow-passthrough is disabled.", {
        "Use `set -gq allow-passthrough on` in tmux or install ueberzugpp.",
        "No edité tmux/.config/tmux/oh-my-tmux automáticamente porque el repo contiene estado git anidado allí.",
      })
    end
  end

  health.start("LVim language bootstrap")
  if env.go_toolchain_available() then
    health.ok("Go toolchain detected; gopls bootstrap is enabled.")
  else
    health.warn("Go toolchain not detected; gopls is skipped during Mason bootstrap.", {
      "Install `go` and rerun ./scripts/lvim-refresh.sh to enable gopls bootstrap.",
    })
  end

  health.start("LVim authoring and debug extras")
  if vim.fn.executable("latexmk") == 1 then
    health.ok("latexmk está disponible para VimTeX.")
  else
    health.warn("latexmk no está instalado.", {
      "Instálalo para evitar warnings y habilitar compilación real con VimTeX.",
    })
  end
  local js_debug_server = joinpath(vim.fn.stdpath("data"), "mason", "packages", "js-debug-adapter", "js-debug", "src", "dapDebugServer.js")
  if vim.fn.filereadable(js_debug_server) == 1 then
    health.ok("JS debug adapter está instalado en Mason.")
  else
    health.warn("JS debug adapter aún no está instalado en Mason.", {
      "Ejecuta ./scripts/lvim-bootstrap.sh o ./scripts/lvim-refresh.sh.",
    })
  end
  local debugpy_python = joinpath(vim.fn.stdpath("data"), "mason", "packages", "debugpy", "venv", "bin", "python")
  if vim.fn.executable(debugpy_python) == 1 then
    health.ok("debugpy está listo para DAP Python.")
  else
    health.warn("debugpy no está listo todavía.", {
      "Ejecuta ./scripts/lvim-bootstrap.sh o ./scripts/lvim-refresh.sh.",
    })
  end

  health.start("LVim PDSL tooling")
  local pdsl_ls = find_upwards("wm-shared/.config/wm-shared/scripts/bin/system/pdsl_ls.py")
  if pdsl_ls then
    health.ok("pdsl_ls.py encontrado: " .. pdsl_ls)
  else
    health.error("pdsl_ls.py no fue encontrado desde el árbol del repo.")
  end
  local pdsl_lint = find_upwards("wm-shared/.config/wm-shared/scripts/bin/system/pdsl_lint.hs")
  if pdsl_lint then
    health.ok("pdsl_lint.hs encontrado: " .. pdsl_lint)
  else
    health.error("pdsl_lint.hs no fue encontrado desde el árbol del repo.")
  end
end

return M
