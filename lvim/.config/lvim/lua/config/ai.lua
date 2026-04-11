local env = require("config.env")

local M = {}

local function joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, "/")
end

local function notify(message, level, title)
  vim.notify(message, level or vim.log.levels.INFO, { title = title or "LVim AI" })
end

local function state_dir()
  return joinpath(vim.fn.stdpath("state"), "lvim-ai-state")
end

local function current_profile()
  return require("config.profile").current()
end

local function profile_scope_name()
  local profile = vim.env.LVIM_PROFILE or "personal"
  local machine = vim.env.LVIM_MACHINE_PROFILE or "default-machine"
  return "profile:" .. profile .. "|machine:" .. machine
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
  return {
    kind = "profile",
    name = profile_scope_name(),
  }
end

local function state_path_for(scope)
  local serialized = scope.kind .. "::" .. scope.name
  return joinpath(state_dir(), vim.fn.sha256(serialized) .. ".json")
end

local function legacy_state_path()
  return joinpath(vim.fn.stdpath("state"), "lvim-ai-state.json")
end

local function load_ai_plugins()
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load({ plugins = { "codecompanion.nvim", "copilot.lua" } })
  end
end

local function provider_specs()
  local specs = env.ai_provider_specs()
  for _, backend in ipairs(env.ai_backends()) do
    specs[backend] = vim.tbl_deep_extend("force", {
      api_key_env = env.ai_api_key_env(backend),
      label = backend,
    }, specs[backend] or {})
  end
  return specs
end

local function normalize_model_choices(choices)
  if type(choices) ~= "table" then
    return {}
  end

  local models = {}
  local seen = {}

  local function add_model(value)
    local model = value
    if type(value) == "table" then
      model = value.value or value.model
    end
    if type(model) == "string" and model ~= "" and not seen[model] then
      seen[model] = true
      table.insert(models, model)
    end
  end

  for key, value in pairs(choices) do
    if type(key) == "number" then
      add_model(value)
    elseif type(key) == "string" then
      add_model(key)
    end
  end

  table.sort(models)
  return models
end

local function adapter_for_discovery(backend)
  load_ai_plugins()
  local ok, adapters = pcall(require, "codecompanion.adapters")
  if not ok then
    return nil
  end

  local provider = env.ai_provider_spec(backend)
  local adapter_name = provider and provider.adapter or backend
  local resolved = adapters.resolve(adapter_name)
  if not resolved then
    return nil
  end
  return resolved
end

local function default_state()
  local backend = env.ai_provider()
  return {
    backend = backend,
    model = env.ai_model(backend),
  }
end

local function load_persisted_state()
  local scopes = {
    current_scope(),
    { kind = "profile", name = profile_scope_name() },
    { kind = "legacy", name = "global" },
  }

  for _, scope in ipairs(scopes) do
    local path = scope.kind == "legacy" and legacy_state_path() or state_path_for(scope)
    if vim.fn.filereadable(path) == 1 then
      local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
      if ok and type(decoded) == "table" then
        decoded._scope = scope
        decoded._path = path
        return decoded
      end
      vim.schedule(function()
        notify("No se pudo leer el estado AI persistido; se usaran los defaults.", vim.log.levels.WARN)
      end)
      return {}
    end
  end

  return {}
end

local function initial_state()
  local defaults = default_state()
  local persisted = load_persisted_state()
  local backend = type(persisted.backend) == "string" and persisted.backend or defaults.backend
  local backend_spec = env.ai_provider_spec(backend)
  if backend_spec then
    backend = backend_spec.name
  end
  if not vim.tbl_contains(env.ai_backends(), backend) then
    backend = defaults.backend
  end
  local model = type(persisted.model) == "string" and persisted.model ~= "" and persisted.model or defaults.model
  return {
    backend = backend,
    model = model,
    scope = persisted._scope or current_scope(),
    path = persisted._path or state_path_for(current_scope()),
  }
end

local state = initial_state()

local function credential_status(backend)
  local status = env.ai_provider_status(backend)
  if not status then
    return false, "unsupported"
  end
  if status.api_key_configured then
    if env.ai_api_key_value(backend) then
      return true, "env:" .. status.api_key_env
    end
    if status.provider == "githubmodels" then
      return true, "gh auth token"
    end
    return true, "configured"
  end
  return false, "missing env:" .. (status.api_key_env or "unknown")
end

local function persist_state()
  local ok, payload = pcall(vim.json.encode, {
    backend = state.backend,
    model = state.model,
    scope = state.scope,
  })
  if not ok then
    error("No se pudo serializar el estado AI")
  end
  state.scope = current_scope()
  state.path = state_path_for(state.scope)
  vim.fn.mkdir(state_dir(), "p")
  local result = vim.fn.writefile(vim.split(payload, "\n"), state.path)
  if result ~= 0 then
    error("No se pudo guardar el estado AI en " .. state.path)
  end
end

local function with_codecompanion(fn)
  local ok, codecompanion = pcall(require, "codecompanion")
  if not ok then
    return nil
  end
  return fn(codecompanion)
end

local function sync_last_chat(provider_name, model)
  with_codecompanion(function(codecompanion)
    local chat = codecompanion.last_chat()
    if not chat then
      return
    end
    chat:change_adapter(provider_name, function()
      if model and model ~= "" then
        chat:change_model({ model = model })
      end
    end)
  end)
end

local function apply_backend(choice)
  local backend = type(choice) == "table" and choice.backend or choice
  M.select_backend(backend)
  sync_last_chat(state.backend, state.model)
  notify("Proveedor activo: " .. state.backend .. " / " .. (state.model or M.default_model(state.backend) or "default"), vim.log.levels.INFO, "LVim AI Session")
end

local function apply_model(choice)
  local model = type(choice) == "table" and choice.model or choice
  M.select_model(model)
  sync_last_chat(state.backend, state.model)
  notify("Modelo activo: " .. state.backend .. " / " .. (state.model or "default"), vim.log.levels.INFO, "LVim AI Session")
end

function M.current_backend()
  return state.backend
end

function M.current_model()
  return state.model
end

function M.current_scope()
  return vim.deepcopy(state.scope)
end

function M.state_path()
  return state.path
end

function M.available_backends()
  return env.ai_backends()
end

function M.default_model(backend)
  local adapter = adapter_for_discovery(backend)
  if not adapter or not adapter.schema or not adapter.schema.model then
    return nil
  end
  local model = adapter.schema.model.default
  if type(model) == "function" then
    model = model(adapter)
  end
  if type(model) == "string" and model ~= "" then
    return model
  end
  return nil
end

function M.available_models(backend)
  local adapter = adapter_for_discovery(backend or state.backend)
  if not adapter or not adapter.schema or not adapter.schema.model then
    return {}
  end
  local choices = adapter.schema.model.choices
  if type(choices) == "function" then
    choices = choices(adapter)
  end
  return normalize_model_choices(choices)
end

function M.status_lines()
  local specs = provider_specs()
  local backend = state.backend
  local model = state.model or M.default_model(backend) or env.ai_model(backend) or "default"
  local spec = specs[backend] or {}
  local ready, credential = credential_status(backend)
  return {
    "Backend: " .. backend .. (spec.label and spec.label ~= backend and (" (" .. spec.label .. ")") or ""),
    "Model: " .. model,
    "Scope: " .. state.scope.kind .. " -> " .. state.scope.name,
    "State file: " .. state.path,
    "Credential: " .. credential,
    "Ready: " .. (ready and "yes" or "no"),
  }
end

function M.providers_lines()
  local specs = provider_specs()
  local lines = {}
  for _, backend in ipairs(M.available_backends()) do
    local spec = specs[backend] or {}
    local models = M.available_models(backend)
    local ready, credential = credential_status(backend)
    local marker = backend == state.backend and "*" or "-"
    local label = spec.label and spec.label ~= "" and spec.label or backend
    local model_hint = env.ai_model(backend) or M.default_model(backend) or models[1] or "default"
    table.insert(lines, string.format("%s %s [%s] model=%s auth=%s", marker, backend, label, model_hint, credential))
    if not ready then
      table.insert(lines, "  unavailable until auth is configured")
    end
  end
  return lines
end

function M.resolve_adapter(backend, model)
  local selected_backend = backend or state.backend
  local selected_model = model
  if selected_model == nil or selected_model == "" then
    selected_model = state.model
  end

  local provider = env.ai_provider_spec(selected_backend)
  local adapter_name = provider and provider.adapter or selected_backend

  load_ai_plugins()
  local extension = {}
  local api_key_env = env.ai_api_key_env(selected_backend)
  if api_key_env and (not provider or not provider.native_api_key_fallback or env.ai_api_key_value(selected_backend) or vim.env.LVIM_AI_API_KEY_ENV) then
    extension.env = { api_key = api_key_env }
  end
  if selected_model and selected_model ~= "" then
    extension.schema = { model = { default = selected_model } }
  end

  local ok, adapters = pcall(require, "codecompanion.adapters")
  if not ok then
    return adapter_name
  end
  return adapters.extend(adapter_name, extension)
end

function M.select_backend(backend)
  local spec = env.ai_provider_spec(backend)
  local canonical = spec and spec.name or backend
  if not vim.tbl_contains(M.available_backends(), canonical) then
    error("Proveedor AI no soportado: " .. tostring(backend))
  end

  state.backend = canonical
  local models = M.available_models(canonical)
  if vim.tbl_isempty(models) then
    models = env.ai_model_choices(canonical)
  end
  if not (state.model and vim.tbl_contains(models, state.model)) then
    state.model = env.ai_model(canonical) or M.default_model(canonical)
  end
  persist_state()
end

function M.select_model(model)
  state.model = model
  persist_state()
end

function M.reset()
  local defaults = default_state()
  state.backend = defaults.backend
  state.model = defaults.model
  persist_state()
end

local function select_with_ui(items, prompt, formatter, on_choice)
  vim.ui.select(items, {
    format_item = formatter,
    prompt = prompt,
  }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

local function register_command(name, callback, opts)
  vim.api.nvim_create_user_command(name, callback, opts or {})
end

register_command("LvimAIStatus", function()
  notify(table.concat(M.status_lines(), "\n"))
end, {})

register_command("LvimAIProviders", function()
  notify(table.concat(M.providers_lines(), "\n"))
end, {})

register_command("LvimAISelectProvider", function(args)
  if args.args ~= "" then
    apply_backend(args.args)
    return
  end

  local specs = provider_specs()
  local items = {}
  for _, backend in ipairs(M.available_backends()) do
    local spec = specs[backend] or {}
    table.insert(items, {
      backend = backend,
      label = (spec.label or backend) .. (backend == state.backend and " (actual)" or ""),
    })
  end
  select_with_ui(items, "Selecciona un proveedor AI", function(item)
    return item.label
  end, apply_backend)
end, { nargs = "?" })

register_command("LvimAIUseProvider", function(args)
  apply_backend(args.args)
end, {
  nargs = 1,
  complete = function()
    return M.available_backends()
  end,
})

register_command("LvimAISelectModel", function(args)
  if args.args ~= "" then
    apply_model(args.args)
    return
  end

  local models = M.available_models(state.backend)
  if vim.tbl_isempty(models) then
    models = env.ai_model_choices(state.backend)
  end
  if vim.tbl_isempty(models) then
    notify("No hay modelos declarados para " .. state.backend .. "; usa :LvimAISelectModel <modelo>.", vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, model in ipairs(models) do
    table.insert(items, {
      model = model,
      label = model .. (model == state.model and " (actual)" or ""),
    })
  end
  select_with_ui(items, "Selecciona un modelo AI", function(item)
    return item.label
  end, apply_model)
end, { nargs = "?" })

register_command("LvimAIUseModel", function(args)
  apply_model(args.args)
end, {
  nargs = 1,
  complete = function()
    return env.ai_model_choices(state.backend)
  end,
})

register_command("LvimAIReset", function()
  M.reset()
  sync_last_chat(state.backend, state.model)
  notify("Estado AI restaurado a " .. state.backend .. " / " .. (state.model or M.default_model(state.backend) or "default"), vim.log.levels.INFO, "LVim AI Session")
end, {})

return M
