local M = {}

local lint_group = vim.api.nvim_create_augroup("LvimLint", { clear = true })

local configured_linters = {
  javascript = { "eslint_d" },
  javascriptreact = { "eslint_d" },
  lua = { "luacheck" },
  markdown = { "markdownlint-cli2" },
  mdx = { "markdownlint-cli2" },
  python = { "ruff" },
  sh = { "shellcheck" },
  bash = { "shellcheck" },
  typescript = { "eslint_d" },
  typescriptreact = { "eslint_d" },
  zsh = { "shellcheck" },
}

local function configured_for(bufnr)
  return configured_linters[vim.bo[bufnr].filetype] or {}
end

local function resolve_linter_cmd(spec)
  if not spec then
    return nil
  end

  local cmd = spec.cmd
  if type(cmd) == "function" then
    local ok, resolved = pcall(cmd)
    if not ok then
      return nil
    end
    cmd = resolved
  end

  if type(cmd) ~= "string" or cmd == "" then
    return nil
  end

  return cmd
end

local function linter_available(lint, name)
  local cmd = resolve_linter_cmd(lint.linters[name])
  if not cmd then
    return false
  end

  if cmd:find("/", 1, true) then
    return vim.fn.executable(cmd) == 1 or vim.fn.filereadable(cmd) == 1
  end

  return vim.fn.executable(cmd) == 1
end

function M.available_linters(bufnr)
  local ok, lint = pcall(require, "lint")
  if not ok then
    return {}
  end

  return vim.tbl_filter(function(name)
    return linter_available(lint, name)
  end, configured_for(bufnr))
end

function M.try_lint(bufnr)
  local ok, lint = pcall(require, "lint")
  if not ok then
    return false
  end

  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "pdsl" then
    return false
  end

  local names = M.available_linters(bufnr)
  if vim.tbl_isempty(names) then
    return false
  end

  vim.api.nvim_buf_call(bufnr, function()
    lint.try_lint(names)
  end)

  return true
end

function M.setup()
  local ok, lint = pcall(require, "lint")
  if not ok then
    return
  end

  lint.linters_by_ft = vim.tbl_deep_extend("force", lint.linters_by_ft or {}, configured_linters)

  if vim.fn.exists(":LvimLint") ~= 2 then
    vim.api.nvim_create_user_command("LvimLint", function(args)
      local bufnr = args.args ~= "" and tonumber(args.args) or vim.api.nvim_get_current_buf()
      local names = M.available_linters(bufnr)
      if vim.tbl_isempty(names) then
        vim.notify("No hay linters configurados o disponibles para este buffer.", vim.log.levels.WARN, { title = "LVim Lint" })
        return
      end
      M.try_lint(bufnr)
    end, { nargs = "?" })
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = lint_group,
    callback = function(args)
      M.try_lint(args.buf)
    end,
  })
end

function M.configured_linters()
  return vim.deepcopy(configured_linters)
end

return M
