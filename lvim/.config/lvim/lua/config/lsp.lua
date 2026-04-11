---@diagnostic disable: undefined-global

local skipped_servers = {
  "yamlls",
  "jsonls",
  "bashls",
  "taplo",
  "clangd",
  "gopls",
  "rust_analyzer",
  "pyright",
  "basedpyright",
  "lua_ls",
  "tsserver",
  "tailwindcss",
}

local ok_schemastore, schemastore = pcall(require, "schemastore")
local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
local env = require("config.env")

lvim.lsp.automatic_configuration = lvim.lsp.automatic_configuration or {}
lvim.lsp.automatic_configuration.skipped_servers = lvim.lsp.automatic_configuration.skipped_servers or {}

for _, server in ipairs(skipped_servers) do
  if not vim.tbl_contains(lvim.lsp.automatic_configuration.skipped_servers, server) then
    table.insert(lvim.lsp.automatic_configuration.skipped_servers, server)
  end
end

local function lsp_capabilities()
  local base = vim.lsp.protocol.make_client_capabilities()
  local blink_ok, blink = pcall(require, "blink.cmp")
  if blink_ok and blink.get_lsp_capabilities then
    return blink.get_lsp_capabilities(base)
  end
  return base
end

local function manager_setup(server, opts)
  opts = opts or {}
  opts.capabilities = vim.tbl_deep_extend("force", lsp_capabilities(), opts.capabilities or {})
  if lvim.lsp and lvim.lsp.manager and lvim.lsp.manager.setup then
    lvim.lsp.manager.setup(server, opts)
  end
end

local function direct_setup(server, opts)
  opts = opts or {}
  opts.capabilities = vim.tbl_deep_extend("force", lsp_capabilities(), opts.capabilities or {})
  if ok_lspconfig and lspconfig[server] and lspconfig[server].setup then
    lspconfig[server].setup(opts)
  end
end

local json_schemas = ok_schemastore and schemastore.json.schemas() or {}
local yaml_schemas = ok_schemastore and schemastore.yaml.schemas() or {}

manager_setup("jsonls", {
  settings = {
    json = {
      format = { enable = true },
      schemas = json_schemas,
      validate = { enable = true },
    },
  },
})

manager_setup("yamlls", {
  settings = {
    yaml = {
      format = { enable = true },
      keyOrdering = false,
      schemaStore = {
        enable = false,
        url = "",
      },
      schemas = yaml_schemas,
      validate = true,
    },
  },
})

manager_setup("bashls", {
  filetypes = { "sh", "bash", "zsh" },
})

manager_setup("taplo", {})

manager_setup("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
})

direct_setup("basedpyright", {
  before_init = function(_, config)
    config.settings = config.settings or {}
    config.settings.python = config.settings.python or {}
    config.settings.python.pythonPath = env.project_python(vim.fn.getcwd())
  end,
  settings = {
    basedpyright = {
      analysis = {
        autoImportCompletions = true,
        autoSearchPaths = true,
        typeCheckingMode = "basic",
        useLibraryCodeForTypes = true,
      },
    },
    python = {
      analysis = {
        autoImportCompletions = true,
        autoSearchPaths = true,
        typeCheckingMode = "basic",
        useLibraryCodeForTypes = true,
      },
    },
  },
})

direct_setup("pyright", {
  autostart = false,
  filetypes = {},
  single_file_support = false,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "pyright" then
      return
    end

    vim.schedule(function()
      vim.lsp.buf_detach_client(args.buf, client.id)
      client:stop()
    end)
  end,
})

manager_setup("lua_ls", {
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace",
      },
      diagnostics = {
        globals = { "vim", "lvim", "Snacks" },
      },
      hint = {
        enable = true,
      },
      telemetry = {
        enable = false,
      },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
})

manager_setup("tsserver", {
  init_options = {
    hostInfo = "lvim",
    preferences = {
      importModuleSpecifierPreference = "non-relative",
      includeCompletionsForModuleExports = true,
    },
  },
  single_file_support = false,
})

manager_setup("tailwindcss", {
  filetypes = {
    "astro",
    "css",
    "eruby",
    "heex",
    "html",
    "javascript",
    "javascriptreact",
    "markdown",
    "mdx",
    "svelte",
    "typescript",
    "typescriptreact",
    "vue",
  },
})

manager_setup("gopls", {
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      gofumpt = true,
      staticcheck = true,
      usePlaceholders = true,
    },
  },
})

manager_setup("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      checkOnSave = {
        command = "clippy",
      },
    },
  },
})
