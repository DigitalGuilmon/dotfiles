---@diagnostic disable: undefined-global

local M = {}
local uv = vim.uv or vim.loop
local profile = require("config.profile").current()
local AI_PROVIDER_ORDER = { "claude", "gemini", "openai", "xai", "deepseek", "githubmodels" }
local AI_PROVIDERS = {
  claude = {
    adapter = "anthropic",
    api_key_envs = { "CLAUDE_API_KEY", "ANTHROPIC_API_KEY" },
    model_envs = { "CLAUDE_MODEL", "ANTHROPIC_MODEL" },
    models = { "claude-sonnet-4-20250514", "claude-3-7-sonnet-20250219", "claude-3-5-haiku-latest" },
  },
  gemini = {
    adapter = "gemini",
    api_key_envs = { "GEMINI_API_KEY", "GOOGLE_API_KEY" },
    model_envs = { "GEMINI_MODEL", "GOOGLE_MODEL" },
    models = { "gemini-2.5-pro", "gemini-2.5-flash", "gemini-2.0-flash" },
  },
  openai = {
    adapter = "openai",
    api_key_envs = { "OPENAI_API_KEY" },
    model_envs = { "OPENAI_MODEL" },
    models = { "gpt-4.1", "gpt-4.1-mini", "gpt-4o" },
  },
  xai = {
    adapter = "xai",
    api_key_envs = { "XAI_API_KEY" },
    model_envs = { "XAI_MODEL" },
    models = { "grok-beta" },
  },
  deepseek = {
    adapter = "deepseek",
    api_key_envs = { "DEEPSEEK_API_KEY" },
    model_envs = { "DEEPSEEK_MODEL" },
    models = { "deepseek-chat", "deepseek-reasoner" },
  },
  githubmodels = {
    adapter = "githubmodels",
    api_key_envs = { "GITHUB_TOKEN", "GH_TOKEN" },
    model_envs = { "GITHUB_MODEL", "GITHUB_MODELS_MODEL" },
    models = { "gpt-4o", "gpt-4o-mini", "o3-mini" },
    native_api_key_fallback = true,
  },
}
local AI_PROVIDER_ALIASES = {
  anthropic = "claude",
  claude = "claude",
  deepseek = "deepseek",
  gemini = "gemini",
  google = "gemini",
  github = "githubmodels",
  githubmodels = "githubmodels",
  ghmodels = "githubmodels",
  gpt = "openai",
  openai = "openai",
  xai = "xai",
  grok = "xai",
}

local function joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, "/")
end

local function current_script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then
    local source_path = source:sub(2)
    if uv and uv.fs_realpath then
      source_path = uv.fs_realpath(source_path) or source_path
    else
      source_path = vim.fn.resolve(source_path)
    end
    return vim.fn.fnamemodify(source_path, ":p:h")
  end
  return vim.fn.getcwd()
end

local function find_upwards(relative_path)
  local dir = current_script_dir()
  while dir and dir ~= "" and dir ~= "/" do
    local candidate = joinpath(dir, relative_path)
    if vim.fn.isdirectory(candidate) == 1 or vim.fn.filereadable(candidate) == 1 then
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

-- Environment knobs used by this config:
--   LVIM_PROFILE           -> selects one or more config.profiles.<name> entries (comma-separated)
--   LVIM_MACHINE_PROFILE   -> selects one or more machine overlays from config.profiles.<name>
--   NVIM_PYTHON3_HOST_PROG -> preferred Python for Mason/LVim integrations
--   OBSIDIAN_VAULT_DIR     -> overrides the default Obsidian workspace path
--   OBSIDIAN_WORKSPACE_NAME-> overrides the displayed Obsidian workspace name
--   LVIM_SPOON_LSP_ENABLED -> enables the optional Spoon Java LSP integration
--   SPOON_JDT_LSP_JAR      -> points to a local Spoon JDT LSP fat JAR
--   SPOON_JDT_LSP_DIR      -> points to a built spoon-jdt-lsp source checkout
--   LVIM_AI_PROVIDER       -> selects the CodeCompanion provider (claude, gemini, openai)
--   LVIM_AI_BACKEND        -> legacy alias for LVIM_AI_PROVIDER
--   LVIM_AI_API_KEY_ENV    -> explicit env var name containing the selected provider API key
--   LVIM_AI_MODEL          -> explicit model override for the selected provider
--   CLAUDE_API_KEY / ANTHROPIC_API_KEY, GEMINI_API_KEY / GOOGLE_API_KEY, OPENAI_API_KEY
--                           -> provider credentials used for automatic selection/fallback
--   LVIM_REPL_SHELL        -> preferred shell executable for Iron repl_definition.sh
--   LVIM_REPL_PYTHON       -> preferred Python executable for Iron repl_definition.python
--   LVIM_HEADLESS_SANITY   -> suppresses expected warnings during scripted headless checks

local function expand(path)
  return vim.fn.expand(path)
end

local function normalize_target_path(target)
  if type(target) == "number" then
    local bufname = vim.api.nvim_buf_get_name(target)
    if bufname ~= "" then
      return bufname
    end
  elseif type(target) == "string" and target ~= "" then
    return expand(target)
  end
  return nil
end

local function parent_dir(path)
  return vim.fn.fnamemodify(path, ":p:h")
end

local function executable_path(candidate)
  if not candidate or candidate == "" then
    return nil
  end

  if candidate:find("/") then
    local path = expand(candidate)
    return vim.fn.executable(path) == 1 and path or nil
  end

  local path = vim.fn.exepath(candidate)
  return path ~= "" and path or nil
end

local function env_value(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  local value = vim.env[name]
  if type(value) == "string" and value ~= "" then
    return value
  end
  return nil
end

local function normalize_ai_provider(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  return AI_PROVIDER_ALIASES[vim.trim(name):lower()] or vim.trim(name):lower()
end

local function ai_provider_spec(name)
  local provider = normalize_ai_provider(name)
  if not provider then
    return nil, nil
  end
  return AI_PROVIDERS[provider], provider
end

local function provider_has_api_key(name)
  local spec = ai_provider_spec(name)
  if not spec then
    return false
  end
  for _, candidate in ipairs(spec.api_key_envs or {}) do
    if env_value(candidate) then
      return true
    end
  end
  return false
end

local function session_ai_provider_override()
  return normalize_ai_provider(vim.g.lvim_ai_provider_override)
end

local function session_ai_model_overrides()
  if type(vim.g.lvim_ai_model_overrides) ~= "table" then
    vim.g.lvim_ai_model_overrides = {}
  end
  return vim.g.lvim_ai_model_overrides
end

function M.first_executable(candidates)
  for _, candidate in ipairs(candidates) do
    local path = executable_path(candidate)
    if path then
      return path
    end
  end
  return nil
end

function M.first_readable_path(candidates)
  for _, candidate in ipairs(candidates) do
    local path = expand(candidate)
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return nil
end

function M.first_glob_match(patterns)
  for _, pattern in ipairs(patterns) do
    if pattern and pattern ~= "" then
      local matches = vim.fn.glob(expand(pattern), false, true)
      if type(matches) == "table" then
        table.sort(matches)
        for _, match in ipairs(matches) do
          if vim.fn.filereadable(match) == 1 then
            return match
          end
        end
      elseif matches ~= "" and vim.fn.filereadable(matches) == 1 then
        return matches
      end
    end
  end
  return nil
end

function M.first_directory(candidates)
  for _, candidate in ipairs(candidates) do
    if candidate and candidate ~= "" then
      local path = expand(candidate)
      if vim.fn.isdirectory(path) == 1 then
        return path
      end
    end
  end
  return nil
end

function M.is_headless_sanity()
  local value = vim.env.LVIM_HEADLESS_SANITY
  if not value or value == "" then
    return false
  end
  value = value:lower()
  return value == "1" or value == "true" or value == "yes" or value == "on"
end

function M.has_ui()
  return #vim.api.nvim_list_uis() > 0
end

function M.feature_enabled(name, default)
  local features = profile.features or {}
  local value = features[name]
  if value == nil then
    return default == nil and false or default
  end
  return value == true
end

function M.preferred_python()
  return M.first_executable({
    vim.env.NVIM_PYTHON3_HOST_PROG,
    "python3",
    "python",
    "/opt/homebrew/bin/python3",
  })
end

function M.project_root(target, markers)
  local candidate_path = normalize_target_path(target)
  local root_markers = markers or { ".git" }

  if vim.fs and vim.fs.root then
    if type(target) == "number" then
      local root = vim.fs.root(target, root_markers)
      if root then
        return root
      end
    end
    if candidate_path then
      local root = vim.fs.root(candidate_path, root_markers)
      if root then
        return root
      end
    end
  end

  local search_dir = candidate_path and parent_dir(candidate_path) or vim.fn.getcwd()
  local found = vim.fs.find(root_markers, { path = search_dir, upward = true })[1]
  if found then
    return parent_dir(found)
  end

  return candidate_path and parent_dir(candidate_path) or vim.fn.getcwd()
end

function M.project_python(target)
  local workspace = M.project_root(target, {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  })
  return M.first_executable({
    joinpath(workspace, ".venv", "bin", "python"),
    joinpath(workspace, "venv", "bin", "python"),
    joinpath(workspace, "env", "bin", "python"),
    M.preferred_python(),
  })
end

function M.java_project_root(target)
  local root = M.project_root(target, {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
  })
  local target_path = normalize_target_path(target)
  if not target_path then
    return nil
  end
  local target_dir = parent_dir(target_path)
  if root == target_dir and vim.fn.filereadable(joinpath(root, "pom.xml")) == 0
    and vim.fn.filereadable(joinpath(root, "build.gradle")) == 0
    and vim.fn.filereadable(joinpath(root, "build.gradle.kts")) == 0
    and vim.fn.filereadable(joinpath(root, "settings.gradle")) == 0
    and vim.fn.filereadable(joinpath(root, "settings.gradle.kts")) == 0 then
    return nil
  end
  return root
end

function M.obsidian_vault_dir()
  local preferred = vim.env.OBSIDIAN_VAULT_DIR or profile.obsidian_vault_dir or "~/vaults/personal"
  local path = M.first_directory({
    joinpath(vim.fn.getcwd(), "vaults", "personal"),
    find_upwards("vaults/personal"),
    find_upwards("dotfiles/vaults/personal"),
    joinpath(expand("~"), "dotfiles", "vaults", "personal"),
    preferred,
  })
  if path then
    return path
  end

  path = expand(preferred)
  vim.fn.mkdir(path, "p")
  return path
end

function M.obsidian_workspace_name()
  return vim.env.OBSIDIAN_WORKSPACE_NAME or profile.obsidian_workspace_name or "personal"
end

function M.obsidian_templates_dir()
  return M.obsidian_vault_dir() .. "/templates"
end

function M.spoon_lsp_jar()
  local source_dir = M.spoon_lsp_source_dir()
  return M.first_readable_path({
    vim.env.SPOON_JDT_LSP_JAR or "",
    unpack(profile.spoon_lsp_jar_candidates or {}),
  }) or M.first_glob_match({
    "~/dev/spoon-jdt-lsp/target/*jar-with-dependencies.jar",
    "~/dev/spoon-jdt-lsp/target/*.jar",
    "~/dev/lsp_base/spoon-jdt-lsp/target/*jar-with-dependencies.jar",
    "~/dev/lsp_base/spoon-jdt-lsp/target/*.jar",
    joinpath(current_script_dir(), "spoon-jdt-lsp/target/*jar-with-dependencies.jar"),
    joinpath(current_script_dir(), "spoon-jdt-lsp/target/*.jar"),
    source_dir and joinpath(source_dir, "target/*jar-with-dependencies.jar") or nil,
    source_dir and joinpath(source_dir, "target/*.jar") or nil,
  })
end

function M.spoon_lsp_source_dir()
  return M.first_directory({
    vim.env.SPOON_JDT_LSP_DIR or "",
    unpack(profile.spoon_lsp_source_dir_candidates or {}),
    "~/dev/spoon-jdt-lsp",
    "~/dev/lsp_base/spoon-jdt-lsp",
    joinpath(current_script_dir(), "spoon-jdt-lsp"),
    joinpath(current_script_dir(), "lsp_base/spoon-jdt-lsp"),
  })
end

local function classpath_separator()
  local os_name = uv and uv.os_uname and uv.os_uname().sysname or ""
  return os_name:match("Windows") and ";" or ":"
end

function M.spoon_lsp_command()
  local java = M.first_executable({ "java" })
  if not java then
    return nil, { reason = "java no esta en PATH" }
  end

  local jar = M.spoon_lsp_jar()
  if jar then
    return { java, "-jar", jar }, { kind = "jar", location = jar }
  end

  local source_dir = M.spoon_lsp_source_dir()
  if not source_dir then
    return nil, { reason = "no se encontró SPOON_JDT_LSP_JAR ni SPOON_JDT_LSP_DIR" }
  end

  local classes_dir = joinpath(source_dir, "target", "classes")
  if vim.fn.isdirectory(classes_dir) ~= 1 then
    return nil, { reason = "faltan clases compiladas en " .. classes_dir }
  end

  local dependencies = vim.fn.glob(joinpath(source_dir, "target", "dependency", "*.jar"), false, true)
  if type(dependencies) ~= "table" or vim.tbl_isempty(dependencies) then
    return nil, { reason = "faltan dependencias copiadas en " .. joinpath(source_dir, "target", "dependency") }
  end
  table.sort(dependencies)

  local entries = { classes_dir }
  vim.list_extend(entries, dependencies)
  return {
    java,
    "-cp",
    table.concat(entries, classpath_separator()),
    "com.lsp.spoon.SpoonLspLauncher",
  }, { kind = "source", location = source_dir }
end

function M.spoon_lsp_status()
  if not M.spoon_lsp_enabled() then
    return { enabled = false, ready = false, reason = "deshabilitado para el perfil actual" }
  end

  local cmd, meta = M.spoon_lsp_command()
  if cmd then
    meta.enabled = true
    meta.ready = true
    meta.command = cmd
    return meta
  end

  meta.enabled = true
  meta.ready = false
  return meta
end

function M.spoon_lsp_enabled()
  local value = vim.env.LVIM_SPOON_LSP_ENABLED
  if value and value ~= "" then
    value = value:lower()
    return value == "1" or value == "true" or value == "yes" or value == "on"
  end
  return profile.spoon_lsp_enabled == true
end

function M.vimtex_view()
  if executable_path("zathura") then
    return { method = "zathura" }
  end
  if executable_path("skim") then
    return { method = "skim" }
  end
  local os_name = uv and uv.os_uname and uv.os_uname().sysname or ""
  return { method = "general", viewer = os_name == "Darwin" and "open" or "xdg-open" }
end

function M.ai_backend()
  return M.ai_provider()
end

local function default_provider_label(provider_name)
  local labels = {
    claude = "Anthropic",
    deepseek = "DeepSeek",
    gemini = "Gemini",
    githubmodels = "GitHub Models",
    openai = "OpenAI",
    xai = "xAI",
  }
  return labels[provider_name] or provider_name
end

function M.ai_backends()
  local configured = profile.ai_backends or AI_PROVIDER_ORDER
  local backends = {}
  local seen = {}

  for _, provider_name in ipairs(configured) do
    local normalized = normalize_ai_provider(provider_name)
    if normalized and AI_PROVIDERS[normalized] and not seen[normalized] then
      seen[normalized] = true
      table.insert(backends, normalized)
    end
  end

  if vim.tbl_isempty(backends) then
    return vim.deepcopy(AI_PROVIDER_ORDER)
  end

  return backends
end

function M.ai_provider()
  local explicit = session_ai_provider_override() or normalize_ai_provider(vim.env.LVIM_AI_PROVIDER or vim.env.LVIM_AI_BACKEND)
  if explicit then
    return explicit
  end

  local preferred = normalize_ai_provider(profile.ai_provider or profile.ai_backend)
  if preferred and provider_has_api_key(preferred) then
    return preferred
  end

  for _, provider_name in ipairs(M.ai_backends()) do
    if provider_has_api_key(provider_name) then
      return provider_name
    end
  end

  return preferred or M.ai_backends()[1] or "gemini"
end

function M.ai_provider_spec(provider_name)
  local spec, canonical = ai_provider_spec(provider_name or M.ai_provider())
  if not spec then
    return nil
  end

  local profile_spec = profile.ai_provider_specs and profile.ai_provider_specs[canonical] or {}
  return vim.tbl_deep_extend("force", vim.deepcopy(spec), profile_spec, {
    name = canonical,
    label = profile_spec.label or default_provider_label(canonical),
  })
end

function M.ai_provider_specs()
  local specs = {}
  for _, provider_name in ipairs(M.ai_backends()) do
    specs[provider_name] = M.ai_provider_spec(provider_name)
  end
  return specs
end

function M.ai_provider_names()
  return vim.deepcopy(M.ai_backends())
end

function M.ai_api_key_value(provider_name)
  local selected_provider = provider_name or M.ai_provider()
  local api_key_env = M.ai_api_key_env(selected_provider)
  return env_value(api_key_env)
end

function M.ai_api_key_env(provider_name)
  local selected_provider = provider_name or M.ai_provider()
  local spec = M.ai_provider_spec(selected_provider)
  if not spec then
    return vim.env.LVIM_AI_API_KEY_ENV or profile.ai_api_key_env or "GEMINI_API_KEY"
  end

  local candidates = {}
  if selected_provider == M.ai_provider() then
    table.insert(candidates, vim.env.LVIM_AI_API_KEY_ENV)
    if type(profile.ai_api_key_env) == "string" then
      table.insert(candidates, profile.ai_api_key_env)
     end
  end
  vim.list_extend(candidates, spec.api_key_envs or {})

  for _, candidate in ipairs(candidates) do
    if env_value(candidate) then
      return candidate
    end
  end

  return candidates[1]
end

function M.ai_model(provider_name)
  local selected_provider = provider_name or M.ai_provider()
  local spec = M.ai_provider_spec(selected_provider)

  local candidates = {}
  table.insert(candidates, session_ai_model_overrides()[selected_provider])
  if selected_provider == M.ai_provider() then
    table.insert(candidates, vim.env.LVIM_AI_MODEL)
    table.insert(candidates, profile.ai_model)
  end
  local profile_models = profile.ai_models or {}
  table.insert(candidates, profile_models[selected_provider])
  if spec then
    vim.list_extend(candidates, spec.model_envs or {})
  end

  for _, candidate in ipairs(candidates) do
    if type(candidate) == "string" and candidate ~= "" then
      local value = env_value(candidate)
      if value then
        return value
      end
      if not AI_PROVIDER_ALIASES[candidate:lower()] and not candidate:match("^[A-Z0-9_]+$") then
        return candidate
      end
    end
  end

  return nil
end

function M.ai_model_choices(provider_name)
  local selected_provider = provider_name or M.ai_provider()
  local spec = M.ai_provider_spec(selected_provider)
  local choices = {}
  local seen = {}

  local function add(choice)
    if type(choice) == "string" and choice ~= "" and not seen[choice] then
      seen[choice] = true
      table.insert(choices, choice)
    end
  end

  add(M.ai_model(selected_provider))
  local profile_models = profile.ai_models or {}
  add(profile_models[selected_provider])
  for _, choice in ipairs(spec and spec.models or {}) do
    add(choice)
  end

  return choices
end

function M.ai_set_session_provider(provider_name)
  local spec = M.ai_provider_spec(provider_name)
  if not spec then
    return nil
  end
  vim.g.lvim_ai_provider_override = spec.name
  vim.g.codecompanion_adapter = spec.name
  return spec.name
end

function M.ai_set_session_model(provider_name, model)
  local selected_provider = provider_name or M.ai_provider()
  local overrides = session_ai_model_overrides()
  if type(model) == "string" and model ~= "" then
    overrides[selected_provider] = model
    vim.g.lvim_ai_model_overrides = overrides
    return model
  end
  overrides[selected_provider] = nil
  vim.g.lvim_ai_model_overrides = overrides
  return nil
end

function M.ai_clear_session_overrides()
  vim.g.lvim_ai_provider_override = nil
  vim.g.codecompanion_adapter = nil
  vim.g.lvim_ai_model_overrides = {}
end

function M.ai_provider_status(provider_name)
  local selected_provider = provider_name or M.ai_provider()
  local spec = M.ai_provider_spec(selected_provider)
  if not spec then
    return nil
  end

  local api_key_env = M.ai_api_key_env(selected_provider)
  local api_key_configured = M.ai_api_key_value(selected_provider) ~= nil
  if not api_key_configured and spec.native_api_key_fallback then
    api_key_configured = vim.fn.executable("gh") == 1
  end

  return {
    provider = spec.name,
    adapter = spec.adapter,
    api_key_env = api_key_env,
    api_key_configured = api_key_configured,
    model = M.ai_model(selected_provider),
    active = selected_provider == M.ai_provider(),
  }
end

function M.ai_available_providers()
  local providers = {}
  for _, provider_name in ipairs(M.ai_backends()) do
    table.insert(providers, M.ai_provider_status(provider_name))
  end
  return providers
end

function M.tmux_allows_passthrough()
  if not vim.env.TMUX or vim.fn.executable("tmux") ~= 1 then
    return false
  end
  local output = vim.fn.system({ "tmux", "show-options", "-gv", "allow-passthrough" })
  if vim.v.shell_error ~= 0 then
    return false
  end
  output = vim.trim(output or ""):lower()
  return output == "on" or output == "all"
end

function M.image_backend_info()
  local term = (vim.env.TERM or ""):lower()
  local term_program = (vim.env.TERM_PROGRAM or ""):lower()
  local supports_kitty_graphics = vim.env.KITTY_WINDOW_ID
    or term:find("kitty", 1, true)
    or term_program == "wezterm"
    or term_program == "ghostty"

  if vim.env.TMUX then
    if M.tmux_allows_passthrough() and supports_kitty_graphics then
      return {
        backend = "kitty",
        reason = "tmux allow-passthrough is enabled; Kitty graphics backend is available.",
      }
    end
    if executable_path("ueberzugpp") then
      return {
        backend = "ueberzug",
        reason = "tmux detected; using ueberzugpp as the safe image backend.",
      }
    end
    return {
      backend = nil,
      reason = "Molten image output is disabled in tmux because allow-passthrough is off and ueberzugpp is not installed.",
    }
  end

  if supports_kitty_graphics then
    return {
      backend = "kitty",
      reason = "Terminal supports Kitty graphics.",
    }
  end
  if executable_path("ueberzugpp") then
    return {
      backend = "ueberzug",
      reason = "ueberzugpp is available as a fallback image backend.",
    }
  end
  return {
    backend = "kitty",
    reason = "Defaulting to Kitty graphics backend outside tmux.",
  }
end

function M.image_backend()
  return M.image_backend_info().backend
end

function M.image_backend_reason()
  return M.image_backend_info().reason
end

function M.go_toolchain_available()
  return executable_path("go") ~= nil
end

function M.notes_autosave_enabled()
  local value = vim.env.LVIM_NOTES_AUTOSAVE
  if value and value ~= "" then
    value = value:lower()
    return value == "1" or value == "true" or value == "yes" or value == "on"
  end
  if profile.notes_autosave_enabled ~= nil then
    return profile.notes_autosave_enabled == true
  end
  return true
end

function M.notes_autosave_filetypes()
  local filetypes = profile.notes_autosave_filetypes or { "gitcommit", "markdown", "mdx", "norg", "org", "rst", "text" }
  local allowed = {}
  for _, filetype in ipairs(filetypes) do
    if type(filetype) == "string" and filetype ~= "" then
      allowed[filetype] = true
    end
  end
  return allowed
end

function M.preferred_shell()
  local candidates = {
    vim.env.LVIM_REPL_SHELL,
    vim.env.SHELL,
  }
  vim.list_extend(candidates, profile.repl_shell_candidates or { "zsh", "sh" })
  return M.first_executable(candidates) or "sh"
end

function M.preferred_repl_python()
  local candidates = {
    vim.env.LVIM_REPL_PYTHON,
  }
  vim.list_extend(candidates, profile.repl_python_candidates or { "ipython", "python3", "python" })
  return M.first_executable(candidates) or "python3"
end

return M
