local env = require("config.env")

local function joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, "/")
end

local function add_neotest_adapter(adapters, module_name, opts)
  local ok, adapter = pcall(require, module_name)
  if not ok then
    return
  end

  if type(adapter) == "function" then
    table.insert(adapters, adapter(opts or {}))
    return
  end

  table.insert(adapters, adapter)
end

local function current_python_for_buffer()
  return env.project_python(vim.api.nvim_get_current_buf())
end

local function js_debug_server_script()
  local script = joinpath(vim.fn.stdpath("data"), "mason", "packages", "js-debug-adapter", "js-debug", "src", "dapDebugServer.js")
  if vim.fn.filereadable(script) == 1 then
    return script
  end
end

local function mason_executable(package, ...)
  local path = joinpath(vim.fn.stdpath("data"), "mason", "packages", package, ...)
  if vim.fn.executable(path) == 1 or vim.fn.filereadable(path) == 1 then
    return path
  end
end

local function first_executable(candidates)
  for _, candidate in ipairs(candidates) do
    if type(candidate) == "string" and candidate ~= "" then
      if candidate:find("/", 1, true) then
        if vim.fn.executable(candidate) == 1 or vim.fn.filereadable(candidate) == 1 then
          return candidate
        end
      elseif vim.fn.executable(candidate) == 1 then
        return candidate
      end
    end
  end
end

local function delve_executable()
  return first_executable({
    mason_executable("delve", "dlv"),
    "dlv",
  })
end

local function codelldb_executable()
  return first_executable({
    mason_executable("codelldb", "extension", "adapter", "codelldb"),
    "codelldb",
  })
end

local function prompt_executable()
  return function()
    local dap = require("dap")
    local path = vim.fn.input({
      prompt = "Path to executable: ",
      default = vim.fn.getcwd() .. "/",
      completion = "file",
    })
    return (path and path ~= "") and path or dap.ABORT
  end
end

local function prompt_args()
  local line = vim.fn.input("Arguments: ")
  if line == nil or line == "" then
    return {}
  end
  return vim.split(vim.trim(line), "%s+")
end

local coverage_state = {}

local function coverage_root()
  return env.project_root(vim.fn.getcwd(), {
    "coverage.json",
    "coverage.xml",
    "lcov.info",
    "cover.out",
    ".git",
  })
end

local function coverage_files_exist(root)
  if not root or root == "" then
    return false
  end
  local candidates = {
    joinpath(root, "coverage.json"),
    joinpath(root, "coverage.xml"),
    joinpath(root, "lcov.info"),
    joinpath(root, "cover.out"),
  }
  for _, candidate in ipairs(candidates) do
    if vim.fn.filereadable(candidate) == 1 then
      return true
    end
  end
  return false
end

local function setup_coverage_ux()
  local ok, coverage = pcall(require, "coverage")
  if not ok then
    return
  end

  vim.api.nvim_create_user_command("LvimCoverageRefresh", function()
    if coverage_files_exist(coverage_root()) then
      coverage.load(true)
      return
    end
    vim.notify("No se encontró reporte de coverage en el proyecto actual.", vim.log.levels.WARN, { title = "LVim Coverage" })
  end, {})

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = { "*.py", "*.ts", "*.tsx", "*.js", "*.jsx", "*.go", "*.rs", "*.lua", "*.c", "*.cpp" },
    callback = function()
      local root = coverage_root()
      if not coverage_files_exist(root) then
        return
      end

      local key = (root or vim.fn.getcwd()) .. "::" .. vim.bo.filetype
      if coverage_state[key] then
        return
      end

      coverage_state[key] = true
      coverage.load(true)
    end,
  })
end

local function js_dap_configurations()
  local dap_utils = require("dap.utils")
  return {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file (Node)",
      program = "${file}",
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      console = "integratedTerminal",
      skipFiles = { "<node_internals>/**", "**/node_modules/**" },
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to running process (Node)",
      processId = dap_utils.pick_process,
      cwd = "${workspaceFolder}",
      skipFiles = { "<node_internals>/**", "**/node_modules/**" },
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Debug Jest current file",
      runtimeExecutable = "node",
      runtimeArgs = {
        "./node_modules/jest/bin/jest.js",
        "--runInBand",
        "${file}",
      },
      rootPath = "${workspaceFolder}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
      skipFiles = { "<node_internals>/**", "**/node_modules/**" },
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Debug Vitest current file",
      runtimeExecutable = "node",
      runtimeArgs = {
        "./node_modules/vitest/vitest.mjs",
        "run",
        "${file}",
      },
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
      skipFiles = { "<node_internals>/**", "**/node_modules/**" },
    },
  }
end

local function go_dap_configurations()
  local dap_utils = require("dap.utils")
  return {
    {
      type = "go",
      name = "Debug current file (Go)",
      request = "launch",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "go",
      name = "Debug package (Go)",
      request = "launch",
      program = "${workspaceFolder}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "go",
      name = "Debug test file (Go)",
      request = "launch",
      mode = "test",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "go",
      name = "Attach to process (Go)",
      request = "attach",
      mode = "local",
      processId = dap_utils.pick_process,
      cwd = "${workspaceFolder}",
    },
  }
end

local function codelldb_configurations(language)
  local dap_utils = require("dap.utils")
  local labels = {
    c = "C",
    cpp = "C++",
    rust = "Rust",
  }
  return {
    {
      type = "codelldb",
      request = "launch",
      name = ("Launch executable (%s)"):format(labels[language] or language),
      program = prompt_executable(),
      cwd = "${workspaceFolder}",
      args = prompt_args,
      stopOnEntry = false,
    },
    {
      type = "codelldb",
      request = "attach",
      name = ("Attach to process (%s)"):format(labels[language] or language),
      pid = dap_utils.pick_process,
      cwd = "${workspaceFolder}",
    },
  }
end

local function register_dap_commands(dap)
  if vim.fn.exists(":LvimDapSelectConfig") ~= 2 then
    vim.api.nvim_create_user_command("LvimDapSelectConfig", function()
      local configs = dap.configurations[vim.bo.filetype] or {}
      if vim.tbl_isempty(configs) then
        vim.notify("No hay configuraciones DAP para este filetype.", vim.log.levels.WARN, { title = "LVim DAP" })
        return
      end

      vim.ui.select(configs, {
        prompt = "Seleccionar configuracion DAP",
        format_item = function(item)
          return item.name
        end,
      }, function(choice)
        if choice then
          dap.run(choice)
        end
      end)
    end, {})
  end

  if vim.fn.exists(":LvimDapRestart") ~= 2 then
    vim.api.nvim_create_user_command("LvimDapRestart", function()
      if type(dap.restart) == "function" then
        dap.restart()
        return
      end
      dap.run_last()
    end, {})
  end
end

local function extend_dap_configurations(dap, language, configurations)
  local merged = vim.deepcopy(dap.configurations[language] or {})
  vim.list_extend(merged, configurations)
  dap.configurations[language] = merged
end

local function setup_dap_stack()
  local dap = require("dap")
  local dapui = require("dapui")

  dapui.setup({
    controls = {
      element = "repl",
      enabled = true,
    },
    floating = {
      border = "rounded",
      mappings = {
        close = { "q", "<Esc>" },
      },
    },
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.45 },
          { id = "watches", size = 0.20 },
          { id = "breakpoints", size = 0.15 },
          { id = "stacks", size = 0.20 },
        },
        position = "left",
        size = 48,
      },
      {
        elements = {
          { id = "repl", size = 0.55 },
          { id = "console", size = 0.45 },
        },
        position = "bottom",
        size = 14,
      },
    },
    render = {
      max_type_length = 80,
    },
  })

  dap.listeners.before.attach.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.launch.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
  end

  local debugpy_python = joinpath(vim.fn.stdpath("data"), "mason", "packages", "debugpy", "venv", "bin", "python")
  if vim.fn.executable(debugpy_python) == 1 then
    require("dap-python").setup(debugpy_python)
  end

  register_dap_commands(dap)

  local js_debug_server = js_debug_server_script()
  if js_debug_server and vim.fn.executable("node") == 1 then
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "127.0.0.1",
      port = "${port}",
      executable = {
        command = "node",
        args = { js_debug_server, "${port}" },
      },
    }
  else
    local reasons = {}
    if not js_debug_server then
      table.insert(reasons, "dapDebugServer.js no existe en Mason")
    end
    if vim.fn.executable("node") ~= 1 then
      table.insert(reasons, "node no esta en PATH")
    end
    if not env.is_headless_sanity() then
      vim.schedule(function()
        vim.notify("JS DAP deshabilitado: " .. table.concat(reasons, "; "), vim.log.levels.WARN)
      end)
    end
  end

  local dlv = delve_executable()
  if dlv then
    dap.adapters.go = {
      type = "server",
      host = "127.0.0.1",
      port = "${port}",
      executable = {
        command = dlv,
        args = { "dap", "-l", "127.0.0.1:${port}" },
      },
    }
    extend_dap_configurations(dap, "go", go_dap_configurations())
  elseif not env.is_headless_sanity() then
    vim.schedule(function()
      vim.notify("Go DAP deshabilitado: `dlv` no esta disponible.", vim.log.levels.WARN)
    end)
  end

  local codelldb = codelldb_executable()
  if codelldb then
    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = {
        command = codelldb,
        args = { "--port", "${port}" },
      },
    }
    for _, language in ipairs({ "c", "cpp", "rust" }) do
      extend_dap_configurations(dap, language, codelldb_configurations(language))
    end
  elseif not env.is_headless_sanity() then
    vim.schedule(function()
      vim.notify("C/C++/Rust DAP deshabilitado: `codelldb` no esta disponible.", vim.log.levels.WARN)
    end)
  end

  extend_dap_configurations(dap, "python", {
    {
      type = "python",
      request = "launch",
      name = "Launch current file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      justMyCode = false,
      pythonPath = function()
        return current_python_for_buffer()
      end,
    },
    {
      type = "python",
      request = "launch",
      name = "pytest current file",
      module = "pytest",
      args = { "${file}", "-q" },
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      justMyCode = false,
      pythonPath = function()
        return current_python_for_buffer()
      end,
    },
  })

  for _, language in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
    extend_dap_configurations(dap, language, js_dap_configurations())
  end
end

return {
  { "kelly-lin/ranger.nvim", main = "ranger-nvim", opts = { replace_netrw = true } },
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip").config.set_config({
        enable_autosnippets = true,
        update_events = "TextChanged,TextChangedI",
      })
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  { "echasnovski/mini.ai", version = false, event = "VeryLazy", opts = {} },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-python",
      "marilari88/neotest-vitest",
      "haydenmeade/neotest-jest",
      "nvim-neotest/neotest-plenary",
    },
    opts = function()
      local adapters = {}
      add_neotest_adapter(adapters, "neotest-python", {
        dap = { justMyCode = false },
        python = function()
          return current_python_for_buffer()
        end,
        runner = "pytest",
      })
      add_neotest_adapter(adapters, "neotest-vitest", {
        filter_dir = function(name)
          return name ~= "node_modules" and name ~= ".git"
        end,
      })
      add_neotest_adapter(adapters, "neotest-jest", {
        jestCommand = "npm test --",
      })
      add_neotest_adapter(adapters, "neotest-plenary")
      return {
        adapters = adapters,
        output = {
          open_on_run = true,
        },
        quickfix = {
          enabled = false,
        },
        summary = {
          follow = true,
          open = "topleft vsplit | vertical resize 40",
        },
      }
    end,
  },
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "Coverage", "CoverageLoad", "CoverageShow", "CoverageHide", "CoverageSummary", "CoverageClear" },
    config = function()
      require("coverage").setup({
        auto_reload = true,
        commands = true,
        highlights = {
          covered = "DiffAdd",
          uncovered = "DiffDelete",
        },
        signs = {
          covered = { hl = "DiffAdd", text = "▎" },
          uncovered = { hl = "DiffDelete", text = "▎" },
        },
        summary = {
          min_coverage = 80.0,
        },
      })
      setup_coverage_ux()
    end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    enabled = env.feature_enabled("database_tools"),
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle" },
  },
  { "mistweaverco/kulala.nvim", enabled = env.feature_enabled("http_tools"), ft = "http", opts = {} },
  { "sindrets/diffview.nvim", cmd = { "DiffviewOpen" } },
  { "Wansmer/treesj", cmd = { "TSJToggle", "TSJJoin", "TSJSplit" }, opts = { use_default_keymaps = false, max_join_length = 150 } },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = {
          enabled = true,
        },
        char = {
          jump_labels = true,
        },
      },
    },
  },
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    config = function(_, opts)
      require("trouble").setup(opts)
      require("config.trouble").setup_command()
    end,
  },
  { "nvim-treesitter/nvim-treesitter-textobjects", dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "theHamsta/nvim-dap-virtual-text", opts = {} },
  { "stevearc/aerial.nvim", cmd = { "AerialToggle", "AerialNavToggle", "AerialNext", "AerialPrev" }, opts = { attach_mode = "global" } },
  { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, opts = { current_line_blame = false } },
  { "folke/todo-comments.nvim", event = { "BufReadPost", "BufNewFile" }, opts = {} },
  { url = "https://git.sr.ht/~whynothugo/lsp_lines.nvim", event = "LspAttach", main = "lsp_lines", opts = {} },
  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
    },
    config = setup_dap_stack,
  },
  { "echasnovski/mini.pairs", version = false, event = "InsertEnter", opts = {} },
  { "NvChad/nvim-colorizer.lua", enabled = env.has_ui(), event = { "BufReadPre", "BufNewFile" }, opts = { user_default_options = { tailwind = true } } },
}
