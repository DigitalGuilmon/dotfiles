local env = require("config.env")

local M = {}

local function assert_command(name)
  assert(vim.fn.exists(":" .. name) == 2, name .. " command is missing")
end

local function wait_for(description, predicate, timeout, interval)
  local ok = vim.wait(timeout or 1500, predicate, interval or 50)
  assert(ok, description)
end

local function read_json(path)
  assert(vim.fn.filereadable(path) == 1, "Expected readable JSON file: " .. path)
  local decoded = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  assert(type(decoded) == "table", "Expected JSON object in " .. path)
  return decoded
end

local function joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, "/")
end

function M.check_command_plugins()
  for _, command in ipairs({
    "Coverage",
    "CoverageHide",
    "CoverageSummary",
    "LvimCoverageRefresh",
    "DiffviewOpen",
  }) do
    assert_command(command)
  end

  if env.feature_enabled("database_tools") then
    for _, command in ipairs({
      "DBUI",
      "DBUIToggle",
      "DBUIFindBuffer",
      "DBUIAddConnection",
    }) do
      assert_command(command)
    end
  end

  if env.feature_enabled("challenge_tools") then
    assert_command("Leet")
  end
end

function M.check_testing_stack()
  local ok_neotest, neotest = pcall(require, "neotest")
  assert(ok_neotest, "neotest module could not be loaded")
  assert(type(neotest.run.run) == "function", "neotest.run.run is unavailable")
  assert(type(neotest.summary.toggle) == "function", "neotest.summary.toggle is unavailable")

  local ok_coverage, coverage = pcall(require, "coverage")
  assert(ok_coverage, "coverage module could not be loaded")
  assert(type(coverage.load) == "function", "coverage.load is unavailable")
end

function M.check_lint_stack()
  local ok_lint, lint = pcall(require, "lint")
  assert(ok_lint, "nvim-lint module could not be loaded")

  local lint_config = require("config.lint")
  local expected = lint_config.configured_linters()
  for filetype, linters in pairs(expected) do
    local actual = lint.linters_by_ft[filetype] or {}
    for _, linter in ipairs(linters) do
      assert(vim.tbl_contains(actual, linter), ("Expected %s linter for %s"):format(linter, filetype))
    end
  end

  assert_command("LvimLint")
end

function M.check_dap()
  local ok_dap, dap = pcall(require, "dap")
  assert(ok_dap, "nvim-dap module could not be loaded")

  assert(#(dap.configurations.python or {}) >= 2, "Python DAP configurations are missing")
  for _, language in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
    assert(#(dap.configurations[language] or {}) > 0, language .. " DAP configurations are missing")
  end

  local js_debug_server = joinpath(vim.fn.stdpath("data"), "mason", "packages", "js-debug-adapter", "js-debug", "src", "dapDebugServer.js")
  if vim.fn.filereadable(js_debug_server) == 1 and vim.fn.executable("node") == 1 then
    assert(dap.adapters["pwa-node"] ~= nil, "pwa-node adapter is missing even though js-debug is installed")
  end

  if vim.fn.executable("dlv") == 1 or vim.fn.filereadable(joinpath(vim.fn.stdpath("data"), "mason", "packages", "delve", "dlv")) == 1 then
    assert(#(dap.configurations.go or {}) >= 3, "Go DAP configurations are missing")
    assert(dap.adapters.go ~= nil, "Go DAP adapter is missing")
  end

  if vim.fn.executable("codelldb") == 1
    or vim.fn.filereadable(joinpath(vim.fn.stdpath("data"), "mason", "packages", "codelldb", "extension", "adapter", "codelldb")) == 1 then
    for _, language in ipairs({ "c", "cpp", "rust" }) do
      assert(#(dap.configurations[language] or {}) >= 2, language .. " codelldb configurations are missing")
    end
    assert(dap.adapters.codelldb ~= nil, "codelldb adapter is missing")
  end

  assert_command("LvimDapSelectConfig")
  assert_command("LvimDapRestart")
end

function M.check_session_commands()
  for _, command in ipairs({
    "LvimSessionSave",
    "LvimSessionLoad",
    "LvimSessionLast",
    "LvimSessionSelect",
    "LvimSessionDelete",
    "LvimSessionStop",
    "LvimWorkspaceClose",
  }) do
    assert_command(command)
  end
end

function M.check_ai_commands()
  for _, command in ipairs({
    "LvimAIStatus",
    "LvimAIProviders",
    "LvimAISelectProvider",
    "LvimAISelectModel",
    "LvimAIReset",
    "LvimSetupInfo",
  }) do
    assert_command(command)
  end
end

function M.check_ai_persistence()
  local ai = require("config.ai")
  local original_backend = ai.current_backend()
  local original_model = ai.current_model()
  local backends = ai.available_backends()
  assert(#backends > 0, "No AI backends are registered")

  local target_backend = original_backend
  for _, backend in ipairs(backends) do
    if backend ~= original_backend then
      target_backend = backend
      break
    end
  end

  ai.select_backend(target_backend)
  local target_model = ai.available_models(target_backend)[1] or ai.default_model(target_backend) or original_model
  if target_model and target_model ~= "" then
    ai.select_model(target_model)
  end

  local persisted = read_json(ai.state_path())
  assert(persisted.backend == target_backend, "Persisted AI backend did not update")
  if target_model and target_model ~= "" then
    assert(persisted.model == target_model, "Persisted AI model did not update")
  end

  ai.select_backend(original_backend)
  if original_model and original_model ~= "" then
    ai.select_model(original_model)
  end

  local restored = read_json(ai.state_path())
  assert(restored.backend == original_backend, "AI backend was not restored after sanity roundtrip")
  if original_model and original_model ~= "" then
    assert(restored.model == original_model, "AI model was not restored after sanity roundtrip")
  end
end

function M.check_obsidian(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  assert(vim.bo[bufnr].filetype == "markdown", "Expected markdown filetype for Obsidian probe")
  assert_command("ObsidianQuickSwitch")
end

function M.check_science()
  if not (env.feature_enabled("notebook_tools") and env.feature_enabled("repl_tools")) then
    return
  end

  assert_command("IronRepl")
  assert_command("IronRestart")
  if vim.fn.exists(":MoltenInit") == 2 then
    assert_command("MoltenInit")
    assert_command("MoltenEvaluateLine")
  end

  local backend = require("config.env").image_backend()
  assert(vim.g.molten_image_provider == (backend and "image.nvim" or "none"), "Molten image provider is inconsistent with env.image_backend()")
  if backend and vim.fn.exists(":MoltenInit") == 2 then
    local ok_image = pcall(require, "image")
    assert(ok_image, "image.nvim should be available when an image backend is selected")
  end
end

function M.check_vimtex(bufnr)
  if not env.feature_enabled("latex_tools") then
    return
  end

  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  assert(vim.bo[bufnr].filetype == "tex", "Expected tex filetype for VimTeX probe")
  for _, command in ipairs({ "VimtexCompile", "VimtexView", "VimtexErrors", "VimtexTocOpen", "VimtexClean" }) do
    assert_command(command)
  end
end

function M.check_tabular(bufnr)
  if not env.feature_enabled("csv_tools") then
    return
  end

  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  assert(vim.tbl_contains({ "csv", "tsv" }, vim.bo[bufnr].filetype), "Expected csv/tsv filetype for tabular probe")
  for _, command in ipairs({ "RainbowDelim", "RainbowAlign", "RainbowShrink", "RainbowQuery", "NoRainbowDelim" }) do
    assert_command(command)
  end
end

function M.check_pdsl(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  assert(vim.bo[bufnr].filetype == "pdsl", "Expected pdsl filetype")
  assert(vim.bo[bufnr].omnifunc == "v:lua.vim.lsp.omnifunc", "PDSL omnifunc is not wired to the LSP omnifunc")

  local ok_lint, lint = pcall(require, "lint")
  assert(ok_lint, "nvim-lint is not available for PDSL validation")
  assert(lint.linters and lint.linters.pdsl, "pdsl lint adapter is not registered")
  assert(vim.tbl_contains(lint.linters_by_ft.pdsl or {}, "pdsl"), "pdsl lint adapter is not mapped to pdsl filetype")

  local ok_configs, configs = pcall(require, "lspconfig.configs")
  assert(ok_configs and configs.pdsl_meta_ls ~= nil, "pdsl_meta_ls is not registered with lspconfig")

  wait_for("pdsl_meta_ls did not attach to the current buffer", function()
    return #vim.lsp.get_clients({ bufnr = bufnr, name = "pdsl_meta_ls" }) > 0
  end)
end

function M.check_java(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  assert(vim.bo[bufnr].filetype == "java", "Expected java filetype")

  local env = require("config.env")
  assert(env.spoon_lsp_enabled(), "Java sanity probe expects LVIM_SPOON_LSP_ENABLED or the java profile to be active")
  assert(env.java_project_root(bufnr) ~= nil, "Java project root could not be detected")

  local cmd, spoon = env.spoon_lsp_command()
  if not cmd then
    vim.api.nvim_out_write("Skipping Spoon attach check because Spoon is not ready: " .. spoon.reason .. "\n")
    return
  end

  wait_for("spoon-lsp did not attach to the current buffer", function()
    return #vim.lsp.get_clients({ bufnr = bufnr, name = "spoon-lsp" }) > 0
  end, 2000, 100)
end

return M
