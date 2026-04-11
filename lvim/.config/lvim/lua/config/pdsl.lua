---@diagnostic disable: undefined-global

local M = {}

vim.filetype.add({
  extension = {
    pdsl = "pdsl",
  },
})

local lsp_ok, lspconfig = pcall(require, "lspconfig")
local server_name = "pdsl_meta_ls"

local function current_script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then
    local source_path = source:sub(2)
    if vim.uv and vim.uv.fs_realpath then
      source_path = vim.uv.fs_realpath(source_path) or source_path
    else
      source_path = vim.fn.resolve(source_path)
    end
    return vim.fn.fnamemodify(source_path, ":p:h")
  end
  return vim.fn.getcwd()
end

local function join_paths(...)
  return table.concat({ ... }, "/")
end

local function find_pdsl_tool(script_name)
  local candidates = {
    vim.fn.expand("~/.config/wm-shared/scripts/bin/system/" .. script_name),
  }

  local dir = current_script_dir()
  while dir and dir ~= "" and dir ~= "/" do
    table.insert(candidates, join_paths(dir, "wm-shared/.config/wm-shared/scripts/bin/system", script_name))
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  for _, candidate in ipairs(candidates) do
    if vim.fn.filereadable(candidate) == 1 then
      return candidate
    end
  end

  return candidates[1]
end

local server_path = find_pdsl_tool("pdsl_ls.py")
local python = vim.fn.exepath("python3")
if python == "" then
  python = vim.fn.exepath("python")
end
local server_cmd = python ~= "" and { python, server_path } or { server_path }

local function pdsl_capabilities()
  local base = vim.lsp.protocol.make_client_capabilities()
  local blink_ok, blink = pcall(require, "blink.cmp")
  if blink_ok and blink.get_lsp_capabilities then
    return blink.get_lsp_capabilities(base)
  end
  return base
end

local function pdsl_root_dir(bufnr)
  if vim.fs and vim.fs.root then
    local root = vim.fs.root(bufnr, { ".git" })
    if root then
      return root
    end
  end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    return vim.fn.getcwd()
  end

  local git_dir = vim.fn.finddir(".git", vim.fn.fnamemodify(bufname, ":p:h") .. ";")
  if git_dir ~= "" then
    return vim.fn.fnamemodify(git_dir, ":h")
  end

  return vim.fn.fnamemodify(bufname, ":p:h")
end

local function ensure_pdsl_lsp_registered()
  if not lsp_ok then
    return
  end

  local configs = require("lspconfig.configs")
  if not configs[server_name] then
    configs[server_name] = {
      default_config = {
        cmd = server_cmd,
        filetypes = { "pdsl" },
        root_dir = function(fname)
          if vim.fs and vim.fs.root then
            return vim.fs.root(fname, { ".git" }) or vim.fs.dirname(fname)
          end
          return vim.fn.fnamemodify(fname, ":p:h")
        end,
        single_file_support = true,
      },
    }
  end
end

local function start_pdsl_lsp(bufnr)
  if lsp_ok then
    return
  end

  local config = {
    name = server_name,
    cmd = server_cmd,
    root_dir = pdsl_root_dir(bufnr),
    capabilities = pdsl_capabilities(),
    single_file_support = true,
  }

  if vim.lsp.start then
    vim.lsp.start(config, {
      bufnr = bufnr,
      reuse_client = function(client, new_config)
        return client.name == new_config.name and client.config.root_dir == new_config.root_dir
      end,
    })
    return
  end

  ensure_pdsl_lsp_registered()
end

local function configure_pdsl_blink()
  local blink_ok, blink = pcall(require, "blink.cmp")
  if not blink_ok then
    return nil
  end

  local config_ok, blink_config = pcall(require, "blink.cmp.config")
  local sources_ok, sources = pcall(require, "blink.cmp.sources.lib")
  if not config_ok or not sources_ok then
    return blink
  end

  blink_config.sources = blink_config.sources or {}
  blink_config.sources.per_filetype = blink_config.sources.per_filetype or {}
  blink_config.sources.per_filetype.pdsl = { "lsp", "path", "snippets" }
  blink_config.sources.providers = blink_config.sources.providers or {}
  blink_config.sources.providers.lsp = vim.tbl_deep_extend("force", blink_config.sources.providers.lsp or {}, {
    score_offset = 120,
  })
  blink_config.sources.providers.buffer = vim.tbl_deep_extend("force", blink_config.sources.providers.buffer or {}, {
    score_offset = -100,
    enabled = function()
      return vim.bo.filetype ~= "pdsl"
    end,
  })
  sources.reload()
  return blink
end

function M.show_completion()
  local blink = configure_pdsl_blink()
  if not blink then
    return
  end
  blink.show({ providers = { "lsp", "path", "snippets" } })
end

if lsp_ok then
  ensure_pdsl_lsp_registered()
  lspconfig[server_name].setup({
    cmd = server_cmd,
    filetypes = { "pdsl" },
    root_dir = function(fname)
      if vim.fs and vim.fs.root then
        return vim.fs.root(fname, { ".git" }) or vim.fs.dirname(fname)
      end
      return vim.fn.fnamemodify(fname, ":p:h")
    end,
    single_file_support = true,
    capabilities = pdsl_capabilities(),
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "pdsl",
  callback = function(args)
    if not lsp_ok then
      start_pdsl_lsp(args.buf)
    end
    vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    vim.opt_local.completeopt = { "menu", "menuone", "noselect", "popup" }
    configure_pdsl_blink()
  end,
})

local ok, lint = pcall(require, "lint")
if not ok then
  return M
end

local lint_cmd = find_pdsl_tool("pdsl_lint.hs")
local lint_generation = {}

local function parse_pdsl_lint(output, bufnr)
  local diagnostics = {}
  local lines = vim.split(output or "", "\n", { trimempty = true })
  local current_buf = vim.api.nvim_buf_get_name(bufnr)

  for _, line in ipairs(lines) do
    local file, lnum, col, severity_name, message = line:match("^(.-):(%d+):(%d+):%s+(error|warning):%s+(.*)$")
    if file and message and (file == current_buf or file == "stdin") then
      table.insert(diagnostics, {
        lnum = math.max(0, tonumber(lnum) - 1),
        col = math.max(0, tonumber(col) - 1),
        end_lnum = math.max(0, tonumber(lnum) - 1),
        end_col = math.max(1, tonumber(col) + 120),
        severity = severity_name == "warning" and vim.diagnostic.severity.WARN or vim.diagnostic.severity.ERROR,
        source = "pdsl-lint",
        message = message,
      })
    end
  end

  return diagnostics
end

lint.linters.pdsl = {
  cmd = "sh",
  stdin = true,
  args = { lint_cmd, "--stdin", "--path", "%filepath" },
  stream = "stdout",
  ignore_exitcode = true,
  parser = parse_pdsl_lint,
}

lint.linters_by_ft = lint.linters_by_ft or {}
lint.linters_by_ft.pdsl = { "pdsl" }

local function run_pdsl_lint(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_call(bufnr, function()
    lint.try_lint("pdsl")
  end)
end

local function schedule_pdsl_lint(bufnr, delay)
  lint_generation[bufnr] = (lint_generation[bufnr] or 0) + 1
  local generation = lint_generation[bufnr]
  vim.defer_fn(function()
    if lint_generation[bufnr] ~= generation then
      return
    end
    run_pdsl_lint(bufnr)
  end, delay)
end

vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
  pattern = "*.pdsl",
  callback = function(args)
    schedule_pdsl_lint(args.buf, 400)
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.pdsl",
  callback = function(args)
    run_pdsl_lint(args.buf)
  end,
})

return M
