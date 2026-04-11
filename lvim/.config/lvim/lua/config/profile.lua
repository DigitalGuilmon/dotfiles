---@diagnostic disable: undefined-global

local M = {}

local function load_profile(name)
  local module_name = "config.profiles." .. name
  local ok, profile = pcall(require, module_name)
  if ok then
    return profile
  end

  if type(profile) == "string" and profile:find(("module '%s' not found"):format(module_name), 1, true) then
    error(("Unknown LVim profile '%s'"):format(name))
  end

  error(profile)
end

local function requested_profiles()
  -- Available profiles:
  --   minimal   -> lean baseline with extras disabled and notes autosave off
  --   personal  -> daily driver with notes + common data/api helpers
  --   frontend  -> TS/JS/UI focused overlay with HTTP helpers and GitHub Models
  --   backend   -> API/backend overlay with DB + HTTP helpers
  --   challenge -> LeetCode/problem-solving extras
  --   debug     -> debugging/service-triage overlay with notes autosave off
  --   research  -> LaTeX, notebooks, REPL workflows, CSV helpers
  --   writing   -> markdown/notes/LaTeX writing overlay
  --   java      -> Spoon Java LSP integration
  -- Machine overlays:
  --   laptop     -> lean host overlay for portable machines
  --   workstation-> full-fat overlay for a powerful desktop
  --   mac_air_m4 -> tuned overlay for the MacBook Air M4
  --   ryzen_9_5950x -> tuned overlay for the Ryzen 9 5950X workstation
  -- Set LVIM_MACHINE_PROFILE for optional host-specific overlays.
  -- Profiles can be stacked, e.g. personal,java or personal,research.
  local raw = vim.env.LVIM_PROFILE or "personal"
  local profiles = {}
  for _, profile_name in ipairs(vim.split(raw, ",", { trimempty = true })) do
    table.insert(profiles, vim.trim(profile_name))
  end
  for _, profile_name in ipairs(vim.split(vim.env.LVIM_MACHINE_PROFILE or "", ",", { trimempty = true })) do
    table.insert(profiles, vim.trim(profile_name))
  end
  if vim.tbl_isempty(profiles) then
    profiles = { "personal" }
  end
  return profiles
end

local function requested_machine_profiles()
  local raw = vim.env.LVIM_MACHINE_PROFILE or ""
  local profiles = {}
  for _, profile_name in ipairs(vim.split(raw, ",", { trimempty = true })) do
    table.insert(profiles, vim.trim(profile_name))
  end
  return profiles
end

function M.current()
  local merged = load_profile("base")
  for _, profile_name in ipairs(requested_profiles()) do
    merged = vim.tbl_deep_extend("force", merged, load_profile(profile_name))
  end
  for _, profile_name in ipairs(requested_machine_profiles()) do
    merged = vim.tbl_deep_extend("force", merged, load_profile(profile_name))
  end
  return merged
end

return M
