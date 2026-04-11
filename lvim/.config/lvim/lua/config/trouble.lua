local M = {}

local function dotset(target, dotted_key, value)
  local current = target
  local parts = vim.split(dotted_key, ".", { plain = true })
  for index = 1, #parts - 1 do
    local part = parts[index]
    if type(current[part]) ~= "table" then
      current[part] = {}
    end
    current = current[part]
  end
  current[parts[#parts]] = value
end

local function parse_value(raw)
  if raw == "true" then
    return true
  end
  if raw == "false" then
    return false
  end
  if raw == "nil" then
    return nil
  end
  if raw:match("^-?%d+$") then
    return tonumber(raw)
  end
  if raw:match("^-?%d+%.%d+$") then
    return tonumber(raw)
  end
  local quoted = raw:match('^"(.*)"$') or raw:match("^'(.*)'$")
  return quoted or raw
end

local function parse_args(input)
  local parsed = {
    mode = nil,
    action = nil,
    opts = {},
  }

  local ok_config, trouble_config = pcall(require, "trouble.config")
  local ok_api, trouble_api = pcall(require, "trouble.api")
  local modes = ok_config and trouble_config.modes() or {}
  local actions = ok_api and vim.tbl_keys(trouble_api) or {}

  for _, token in ipairs(vim.split(vim.trim(input or ""), "%s+", { trimempty = true })) do
    local key, value = token:match("^([%w%._]+)=(.+)$")
    if key then
      dotset(parsed.opts, key, parse_value(value))
    elseif vim.tbl_contains(modes, token) then
      parsed.mode = token
    elseif vim.tbl_contains(actions, token) then
      parsed.action = token
    end
  end

  parsed.action = parsed.action or "open"
  parsed.opts.mode = parsed.opts.mode or parsed.mode or "diagnostics"
  return parsed
end

function M.execute(input)
  local trouble = require("trouble")
  local parsed = parse_args(input)
  return trouble[parsed.action](parsed.opts)
end

function M.complete(arg_lead, cmd_line, cursor_pos)
  local ok_config, trouble_config = pcall(require, "trouble.config")
  local ok_api, trouble_api = pcall(require, "trouble.api")
  if not (ok_config and ok_api) then
    return {}
  end

  local line = cmd_line:sub(1, cursor_pos)
  local used = {}
  for token in line:gmatch("%S+") do
    used[token] = true
  end

  local candidates = {}
  vim.list_extend(candidates, trouble_config.modes())
  vim.list_extend(candidates, vim.tbl_keys(trouble_api))
  vim.list_extend(candidates, {
    "focus=false",
    "focus=true",
    "filter.buf=0",
    "win.position=bottom",
    "win.position=right",
    "win.position=left",
    "win.position=top",
    "new=true",
  })

  local filtered = vim.tbl_filter(function(item)
    return item:find(arg_lead, 1, true) == 1 and not used[item]
  end, candidates)
  table.sort(filtered)
  return filtered
end

function M.setup_command()
  pcall(vim.api.nvim_del_user_command, "Trouble")
  vim.api.nvim_create_user_command("Trouble", function(input)
    M.execute(input.args)
  end, {
    nargs = "*",
    complete = function(arg_lead, cmd_line, cursor_pos)
      return M.complete(arg_lead, cmd_line, cursor_pos)
    end,
    desc = "Trouble",
  })
end

return M
