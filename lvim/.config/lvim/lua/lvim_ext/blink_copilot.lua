local api = require("copilot.api")
local format = require("blink-cmp-copilot.format")
local util = require("copilot.util")

local M = {}

local function current_bufnr(context)
  return (context and context.bufnr) or vim.api.nvim_get_current_buf()
end

local function resolve_client(bufnr)
  local ok_copilot = pcall(require, "copilot")
  if not ok_copilot then
    return nil
  end

  local ok_client, client = pcall(require, "copilot.client")
  if not ok_client or client.is_disabled() then
    return nil
  end

  client.ensure_client_started()

  local active_client = client.get()
  if not active_client then
    return nil
  end

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) and not client.buf_is_attached(bufnr) then
    client.buf_attach(false, bufnr)
  end

  return client.get()
end

function M.get_trigger_characters()
  return { "." }
end

function M:enabled()
  return resolve_client(current_bufnr()) ~= nil
end

function M:get_completions(context, callback)
  local client = resolve_client(current_bufnr(context))
  if not client then
    return callback({
      is_incomplete_forward = true,
      is_incomplete_backward = true,
      items = {},
    })
  end

  api.get_completions(client, util.get_doc_params(), function(err, response)
    if err or not response or not response.completions then
      return callback({
        is_incomplete_forward = true,
        is_incomplete_backward = true,
        items = {},
      })
    end

    local items = vim.tbl_map(function(item)
      return format.format_item(item, context)
    end, vim.tbl_values(response.completions))

    return callback({
      is_incomplete_forward = false,
      is_incomplete_backward = false,
      items = items,
    })
  end)
end

function M:new()
  return setmetatable({}, { __index = M })
end

return M
