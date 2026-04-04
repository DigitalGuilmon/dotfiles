---@diagnostic disable: undefined-global
-- =================================================================
-- 🚀 LUNARVIM 2026 - M4 ULTRA-OPTIMIZED (FULL STACK + AI + OBSIDIAN)
-- =================================================================
-- Silenciar avisos de funciones obsoletas (Deprecation warnings)
-- Esto evitará que los popups de advertencia aparezcan al iniciar

-- Opcional: También puedes silenciar avisos específicos de la API si los anteriores persisten
vim.g.deprecation_warnings = false

-- 0. OPTIMIZACIÓN DE ARRANQUE
if vim.loader then vim.loader.enable() end

-- 1. CONFIGURACIÓN DEL CORE
-- -----------------------------------------------------------------
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.conceallevel = 2 -- Oculta sintaxis Markdown para look Obsidian
vim.opt.laststatus = 3   -- Barra de estado global única
vim.g.material_style = "deep ocean"
vim.list_extend(lvim.builtin.treesitter.ensure_installed, {
  "html", "css", "javascript", "typescript", "tsx", "python", "lua",
  "markdown", "markdown_inline", "yaml", "json", "bash"
})


local undodir = vim.fn.expand("~/.local/state/nvim/undo")
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir

vim.opt.undofile = true
vim.opt.undolevels = 10000
-- Directorio para que no ensucie tus carpetas de proyecto
vim.opt.undodir = vim.fn.expand("~/.local/state/nvim/undo")


lvim.builtin.dap.active = true
lvim.format_on_save.enabled = true
lvim.format_on_save.timeout = 2000 -- Milisegundos que espera al formateador antes de guardar
-- Fuerza a Mason a usar el Python de tu sistema
lvim.builtin.mason.python_path = "/opt/homebrew/bin/python3"


-- Guardado automático al perder el foco (Ideal para Obsidian y notas rápidas)
vim.api.nvim_create_autocmd({ "FocusLost", "WinLeave" }, {
  pattern = "*",
  command = "silent! update",
})

-- 2. DESACTIVAR BUILT-INS (Máximo Rendimiento)
-- -----------------------------------------------------------------
local disabled_builtins = {
  "illuminate", "indentlines", "terminal", "nvimtree",
  "cmp", "telescope", "alpha"
}
for _, builtin in ipairs(disabled_builtins) do
  lvim.builtin[builtin].active = false
end
lvim.builtin.breadcrumbs.active = true

-- 3. DIAGNÓSTICOS (Optimizado para lsp_lines)
-- -----------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { only_current_line = true },
  underline = true,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})


-- =================================================================
-- 📦 PLUGINS (Ecosistema Refinado 2026)
-- =================================================================
lvim.plugins = {
  { "mbbill/undotree",                 cmd = "UndotreeToggle" },
  -- Bind recomendado: m["u"] = { "<cmd>UndotreeToggle<cr>", "Árbol de Deshacer" }
  -- --- [ ESTÉTICA Y UI PREMIUM ] ---
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  { "giuxtaposition/blink-cmp-copilot" },
  {
    "marko-cerovac/material.nvim",
    priority = 1000,
    config = function()
      require('material').setup({
        lualine_style = "stealth",
        async_loading = true,
        custom_colors = function(colors) colors.editor.bg = "#0d1117" end,
      })
      vim.cmd.colorscheme("material")
    end
  },
  { "xiyaowong/transparent.nvim", opts = { extra_groups = { "NormalFloat", "NvimTreeNormal", "CursorLine", "FloatBorder" } } },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = { override = { ["vim.lsp.util.convert_input_to_markdown_lines"] = true, ["vim.lsp.util.stylize_markdown"] = true } },
      presets = { bottom_search = true, command_palette = true, long_message_to_split = true },
    },
  },
  { "stevearc/dressing.nvim",     opts = { input = { border = "rounded" } } },

  -- --- [ NAVEGACIÓN Y ESTRUCTURA ] ---
  { "SmiteshP/nvim-navic",        lazy = true },
  {
    "utilyre/barbecue.nvim",
    event = "LspAttach",
    dependencies = { "SmiteshP/nvim-navic", "nvim-tree/nvim-web-devicons" },
    opts = { theme = 'material', show_modified = true },
  },
  { "stevearc/oil.nvim",     opts = { columns = { "icon" }, float = { border = "rounded" } } },

  -- --- [ RENDIMIENTO M4: BLINK & SNACKS ] ---
  {
    "Saghen/blink.cmp",
    build = 'cargo build --release',
    opts = {
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = 'mono',
        kind_icons = {
          Copilot = "",
          CodeCompanion = "🤖",
          Text = "󰉿",
          Method = "󰊕",
          Function = "󰊕",
          Constructor = "󰒓",
          Field = "󰜢",
          Variable = "󰆦",
          Property = "󰖷",
          Class = "󱡠",
          Interface = "󱡠",
          Module = "󰅩",
          Snippet = "󱄽",
        },
      },
      keymap = {
        preset = 'enter',
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
      },
      -- 👇 MODIFICADO PARA SOPORTAR AUTOSNIPPETS MATEMÁTICOS 👇
      snippets = { preset = 'luasnip' },
      signature = { enabled = true, window = { border = "rounded" } },

      completion = {
        ghost_text = { enabled = true },
        menu = {
          border = "rounded",
          draw = {
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 }, { "source_name" } },
            components = {
              source_name = {
                text = function(ctx) return "[" .. ctx.source_name .. "]" end,
                highlight = "BlinkCmpSource",
              }
            }
          }
        },
        list = { selection = { preselect = true, auto_insert = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
      },

      fuzzy = {
        sorts = { "score", "sort_text" },
        prebuilt_binaries = { download = true },
      },

      cmdline = {
        enabled = true,
        sources = function()
          local type = vim.fn.getcmdtype()
          if type == '/' or type == '?' then return { 'buffer' } end
          if type == ':' then return { 'cmdline' } end
          return {}
        end,
      },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'codecompanion', 'copilot' },
        per_filetype = {
          env = { 'buffer', 'path' },
          markdown = { 'buffer', 'path', 'snippets' },
        },
        providers = {
          lsp = { fallbacks = { "buffer" } },
          copilot = { name = "Copilot", module = "blink-cmp-copilot", score_offset = 100, async = true },
          codecompanion = { name = "CodeCompanion", module = "codecompanion.providers.completion.blink", enabled = true, score_offset = 100, async = true },
          buffer = { score_offset = -10 },
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = { enabled = true },
      notifier = { enabled = false },
      input = { enabled = true },
      picker = { enabled = true, ui_select = true },
      indent = { enabled = true, char = "╎", scope = { enabled = true, char = "┃" } },
      scroll = { enabled = true },
      persistence = { enabled = true },
      lazygit = { enabled = true },
      zen = { enabled = true },
      terminal = { enabled = true },
      scratch = { enabled = true },
      image = { enabled = true },
    },
  },

  -- --- [ INTELIGENCIA ARTIFICIAL: CODECOMPANION ] ---
  {
    "olimorris/codecompanion.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("codecompanion").setup({
        adapters = {
          gemini = function()
            return require("codecompanion.adapters").extend("gemini", {
              env = { api_key = "GEMINI_API_KEY" },
            })
          end,
        },
        strategies = {
          chat = {
            adapter = "gemini",
            roles = {
              llm = "Ingeniero de Software Senior (M4 Optimized)",
              user = "Arquitecto de Sistemas",
            },
          },
          inline = { adapter = "gemini" }
        },
        display = { inline = { diff = { enabled = true, provider = "builtin" } } }
      })
    end,
  },

  -- --- [ NOTAS & RENDERING ] ---
  {
    "epwalsh/obsidian.nvim",
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = { { name = "personal", path = "~/vaults/personal" } },
      ui = { enabled = false },
      templates = { subdir = "templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
    }
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
    opts = {
      preset = "obsidian",
      checkbox = { enabled = true },
      latex = { enabled = true },
    },
  },

  -- --- [ LENGUAJES Y PORTABILIDAD ] ---
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettier", "stylua", "eslint_d", "black", "ruff",
          "pyright", "typescript-language-server", "lua-language-server",
        },
      })
    end,
  },
  { "Julian/lean.nvim",      event = { "BufReadPre *.lean" },                                                       opts = { lsp = {}, mappings = true } },
  { "kelly-lin/ranger.nvim", config = function() require("ranger-nvim").setup({ replace_netrw = true }) end },
  { "kawre/leetcode.nvim",   dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-telescope/telescope.nvim" }, opts = { lang = "cpp" } },
  {
    "lervag/vimtex",
    lazy = false,
    init = function() vim.g.vimtex_view_method = "zathura" end
  },

  -- --- [ CIENCIA DE DATOS Y MATEMÁTICAS ] ---
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
    end,
  },
  {
    "Vigemus/iron.nvim",
    config = function()
      require("iron.core").setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            sh = { command = { "zsh" } },
            python = { command = { "ipython" } },
          },
          repl_open_cmd = require("iron.view").split.vertical.botright(50),
        },
      })
    end,
  },
  {
    "mechatroner/rainbow_csv",
    ft = { "csv", "tsv", "dat" },
    cmd = { "RainbowDelim", "RainbowDelimSimple", "RainbowAlign" }
  },
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

  -- --- [ INGENIERÍA Y EDICIÓN TÁCTICA ] ---
  {
    "echasnovski/mini.ai",
    version = false,
    config = function() require("mini.ai").setup() end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim", "antoinemadec/FixCursorHold.nvim" },
    config = function() require("neotest").setup({ adapters = {} }) end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { { "tpope/vim-dadbod", lazy = true }, { "kristijanhusak/vim-dadbod-completion", ft = { "sql" }, lazy = true } },
    cmd = { "DBUI", "DBUIToggle" },
  },
  { "mistweaverco/kulala.nvim", ft = "http",                                                  opts = {} },
  { "sindrets/diffview.nvim",   cmd = { "DiffviewOpen" } },
  { "Wansmer/treesj",           opts = { use_default_keymaps = false, max_join_length = 150 } },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = { modes = { char = { jump_labels = true } } },
    keys = { { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" }, },
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function() require("nvim-surround").setup() end
  },
  { "folke/trouble.nvim",                                 cmd = "Trouble",                                                    opts = {} },
  { "nvim-treesitter/nvim-treesitter-textobjects",        dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "theHamsta/nvim-dap-virtual-text",                    config = function() require("nvim-dap-virtual-text").setup() end },
  { "stevearc/aerial.nvim",                               opts = { attach_mode = "global" } },
  { "lewis6991/gitsigns.nvim",                            opts = { current_line_blame = true } },
  { "folke/todo-comments.nvim",                           opts = {} },
  { url = "https://git.sr.ht/~whynothugo/lsp_lines.nvim", config = function() require("lsp_lines").setup() end },

  -- --- [ COMPLEMENTOS FALTANTES ] ---
  { "rcarriga/nvim-dap-ui",                               dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
  {
    "echasnovski/mini.pairs",
    version = false,
    config = function() require("mini.pairs").setup() end
  },
  { "NvChad/nvim-colorizer.lua", opts = { user_default_options = { tailwind = true } } },
}



-- =================================================================
-- ⌨️ KEYBINDINGS Y WHICH-KEY
-- =================================================================
local m = lvim.builtin.which_key.mappings


-- 🗺️ Mapa del Código
m["a"] = { "<cmd>AerialToggle!<CR>", "Outline (Aerial)" }
-- 📁 NAVEGACIÓN Y ARCHIVOS DIRECTOS
m["e"] = { function() require("oil").toggle_float() end, "Explorador (Oil)" }
m["r"] = { function() require("ranger-nvim").open(true) end, "Ranger FM" }
m["f"] = { "<cmd>lua Snacks.picker.smart()<cr>", "Smart Find" }

-- 🔍 BÚSQUEDA AVANZADA (Snacks)
m["s"] = {
  name = "Search (Snacks)",
  f = { "<cmd>lua Snacks.picker.files()<cr>", "Archivos" },
  g = { "<cmd>lua Snacks.picker.grep()<cr>", "Grep (Texto)" },
  b = { "<cmd>lua Snacks.picker.buffers()<cr>", "Buffers Activos" },
  n = { "<cmd>lua Snacks.picker.notifications()<cr>", "Notificaciones" },
}

-- 🤖 INTELIGENCIA ARTIFICIAL
m["G"] = {
  name = "IA Gemini",
  c = { "<cmd>CodeCompanionChat Toggle<cr>", "Chat IA" },
  a = { "<cmd>CodeCompanionActions<cr>", "Acciones IA" },
  i = { "<cmd>CodeCompanion<cr>", "Prompt Inline" },
}

-- 📝 OBSIDIAN
m["o"] = {
  name = "Obsidian",
  n = { "<cmd>ObsidianNew<cr>", "Nueva Nota" },
  t = {
    function()
      local templates_dir = vim.fn.expand("~/vaults/personal/templates")
      require("snacks").picker.files({
        cwd = templates_dir,
        title = "Seleccionar Plantilla",
        confirm = function(picker, item)
          picker:close()
          vim.cmd("ObsidianTemplate " .. item.text)
        end,
      })
    end,
    "Insertar Plantilla"
  },
  s = {
    function() require("snacks").picker.files({ cwd = "~/vaults/personal" }) end,
    "Buscar en Vault"
  },
  l = { "<cmd>ObsidianLink<cr>", "Linkear Selección" },
}

-- ⚙️ TOGGLES Y UI
m["t"] = {
  name = "Toggles",
  l = { function()
    local current = vim.diagnostic.config().virtual_lines
    vim.diagnostic.config({ virtual_lines = not current })
  end, "LSP Lines" },
  z = { function() Snacks.zen() end, "Modo Zen" },
}

-- 🎓 ENTORNOS ESPECÍFICOS (Leetcode, LaTeX, Lean)
-- LeetCode
m["C"] = {
  name = "LeetCode",
  c = { "<cmd>Leet<cr>", "Abrir Dashboard" },
  r = { "<cmd>Leet run<cr>", "Ejecutar Código (Run)" },
  s = { "<cmd>Leet submit<cr>", "Enviar Solución (Submit)" },
  l = { "<cmd>Leet list<cr>", "Lista de Problemas" },
  i = { "<cmd>Leet info<cr>", "Info del Problema" },
}

-- LaTeX (Vimtex)
m["L"] = {
  name = "LaTeX",
  c = { "<cmd>VimtexCompile<cr>", "Compilar (Start/Stop)" },
  v = { "<cmd>VimtexView<cr>", "Ver PDF" },
  e = { "<cmd>VimtexErrors<cr>", "Mostrar Errores" },
  t = { "<cmd>VimtexTocOpen<cr>", "Tabla de Contenidos" },
  x = { "<cmd>VimtexClean<cr>", "Limpiar Archivos Auxiliares" },
}

-- Lean 4 (Panel de información interactivo)
m["i"] = { "<cmd>LeanInfoviewToggle<cr>", "Lean Infoview" }

-- =================================================================
-- 💻 HERRAMIENTAS DE INGENIERÍA (Testing, DB, Git, HTTP)
-- =================================================================

-- 🛠️ Refactorización Rápida
m["j"] = { "<cmd>TSJToggle<cr>", "Join/Split Código (TreeSJ)" }

-- 🌐 Cliente HTTP (Kulala)
m["R"] = { "<cmd>lua require('kulala').run()<cr>", "Ejecutar Request HTTP" }

-- 🧪 Testing Integrado (Neotest)
m["T"] = {
  name = "Testing",
  t = { "<cmd>lua require('neotest').run.run()<cr>", "Ejecutar Test Cercano" },
  f = { "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", "Ejecutar Archivo Actual" },
  s = { "<cmd>lua require('neotest').summary.toggle()<cr>", "Panel de Resultados" },
  o = { "<cmd>lua require('neotest').output.open({ enter = true })<cr>", "Ver Output de Test" },
  x = { "<cmd>lua require('neotest').run.stop()<cr>", "Detener Test" },
}

-- 🗄️ Bases de Datos (Dadbod)
m["D"] = {
  name = "Database",
  u = { "<cmd>DBUIToggle<cr>", "Abrir/Cerrar Panel DB" },
  f = { "<cmd>DBUIFindBuffer<cr>", "Buscar Buffer DB" },
  a = { "<cmd>DBUIAddConnection<cr>", "Añadir Conexión" },
}

-- 🔀 Git Avanzado (Diffview)
-- Lo integramos dentro del menú "g" que LunarVim ya usa por defecto para Git
m["g"] = vim.tbl_deep_extend("force", m["g"] or { name = "Git" }, {
  v = { "<cmd>DiffviewOpen<cr>", "Abrir Diffview (3-way merge)" },
  h = { "<cmd>DiffviewFileHistory %<cr>", "Historial del Archivo Actual" },
  x = { "<cmd>DiffviewClose<cr>", "Cerrar Diffview" },
  g = { function() Snacks.lazygit() end, "Abrir Lazygit" },
  l = { function() Snacks.lazygit.log() end, "Git Log (Lazygit)" }
})

-- 🚨 Trouble (Diagnósticos Avanzados)
m["x"] = {
  name = "Trouble (Diagnósticos)",
  x = { "<cmd>Trouble diagnostics toggle<cr>", "Diagnósticos del Proyecto" },
  X = { "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Diagnósticos (Buffer Actual)" },
  q = { "<cmd>Trouble qflist toggle<cr>", "Quickfix List" },
  l = { "<cmd>Trouble loclist toggle<cr>", "Location List" },
  r = { "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", "Referencias LSP" },
}


-- =================================================================
-- 🧩 MAPEOS FALTANTES (COMPLEMENTO)
-- =================================================================

-- 1. SESIONES DE SNACKS (Requerido por tu config: persistence = { enabled = true })
m["q"] = {
  name = "Sesiones (Snacks)",
  s = { function() Snacks.session.load() end, "Restaurar Sesión Actual" },
  l = { function() Snacks.session.load({ last = true }) end, "Restaurar Última Sesión" },
  d = { function() Snacks.session.delete() end, "Borrar Sesión" },
}

-- 2. LAZYGIT (Activaste lazygit en Snacks, pero no tenía tecla de acceso)
m["g"]["g"] = { function() Snacks.lazygit() end, "Abrir Lazygit" }
m["g"]["l"] = { function() Snacks.lazygit.log() end, "Git Log (Lazygit)" }

-- 3. TODO-COMMENTS (Instalado, pero sin forma de buscarlos. Lo enlazamos a Trouble)
m["x"]["t"] = { "<cmd>Trouble todo toggle<cr>", "Ver TODOs del Proyecto" }
m["x"]["T"] = { "<cmd>Trouble todo toggle filter.buf=0<cr>", "Ver TODOs (Buffer Actual)" }

-- 4. NOICE.NVIM (Necesario para limpiar mensajes flotantes que se queden pegados)
m["n"] = {
  name = "Noice UI",
  d = { "<cmd>Noice dismiss<cr>", "Ocultar Notificaciones" },
  h = { "<cmd>Noice history<cr>", "Historial de Mensajes" },
}

-- 5. OBSIDIAN (Faltan las notas diarias y navegación de enlaces)
m["o"]["d"] = { "<cmd>ObsidianToday<cr>", "Nota Diaria (Hoy)" }
m["o"]["b"] = { "<cmd>ObsidianBacklinks<cr>", "Ver Backlinks" }
m["o"]["f"] = { "<cmd>ObsidianFollowLink<cr>", "Seguir Enlace Bajo el Cursor" }


-- 🐞 DEBUGGING (DAP)
m["d"] = {
  name = "Debug (DAP)",
  t = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
  b = { "<cmd>lua require'dap'.step_back()<cr>", "Step Back" },
  c = { "<cmd>lua require'dap'.continue()<cr>", "Continue" },
  C = { "<cmd>lua require'dap'.run_to_cursor()<cr>", "Run To Cursor" },
  d = { "<cmd>lua require'dap'.disconnect()<cr>", "Disconnect" },
  g = { "<cmd>lua require'dap'.session()<cr>", "Get Session" },
  i = { "<cmd>lua require'dap'.step_into()<cr>", "Step Into" },
  o = { "<cmd>lua require'dap'.step_over()<cr>", "Step Over" },
  u = { "<cmd>lua require'dap'.step_out()<cr>", "Step Out" },
  p = { "<cmd>lua require'dap'.pause()<cr>", "Pause" },
  r = { "<cmd>lua require'dap'.repl.toggle()<cr>", "Toggle Repl" },
  s = { "<cmd>lua require'dap'.continue()<cr>", "Start" },
  q = { "<cmd>lua require'dap'.close()<cr>", "Quit" },
  U = { "<cmd>lua require'dapui'.toggle({reset = true})<cr>", "Toggle UI DAP" },
}


-- 🧹 FORMATEO MANUAL
m["F"] = { "<cmd>lua require('lvim.core.formatters').format()<cr>", "Formatear Archivo" }


-- 🍿 SNACKS (Terminal y Scratchpads)
m["S"] = {
  name = "Snacks Extras",
  s = { function() Snacks.scratch() end, "Toggle Scratchpad" },
  S = { function() Snacks.scratch.select() end, "Seleccionar Scratchpad" },
  t = { function() Snacks.terminal() end, "Terminal Flotante" },
}


-- 🔬 EJECUCIÓN CIENTÍFICA (Molten / Jupyter)
m["M"] = {
  name = "Math & Jupyter (Molten)",
  i = { "<cmd>MoltenInit<cr>", "Iniciar Kernel (Python/R/Julia)" },
  e = { "<cmd>MoltenEvaluateOperator<cr>", "Evaluar Bloque/Operador" },
  l = { "<cmd>MoltenEvaluateLine<cr>", "Evaluar Línea" },
  r = { "<cmd>MoltenReevaluateCell<cr>", "Re-evaluar Celda" },
  d = { "<cmd>MoltenDelete<cr>", "Borrar Celda Visual" },
  h = { "<cmd>MoltenHideOutput<cr>", "Ocultar Output/Gráfico" },
}

-- 🔄 REPL INTERACTIVO (Iron)
m["I"] = {
  name = "Interactive REPL (Iron)",
  r = { "<cmd>IronRepl<cr>", "Abrir REPL" },
  s = { "<cmd>IronRestart<cr>", "Reiniciar REPL" },
  f = { "<cmd>IronFocus<cr>", "Enfocar Ventana REPL" },
  h = { "<cmd>IronHide<cr>", "Ocultar REPL" },
}


-- 🩺 LINTERS Y DIAGNÓSTICOS (Navegación Rápida Estilo 2026)
vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Siguiente Diagnóstico" })
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Diagnóstico Anterior" })
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Ver Diagnóstico Flotante" })


-- =================================================================
-- 👁️ MODO VISUAL (CRÍTICO PARA CODECOMPANION Y SNACKS)
-- =================================================================
local vm = lvim.builtin.which_key.vmappings

-- IA en Modo Visual: Seleccionas código y lo mandas directo a Gemini
vm["G"] = {
  name = "IA Gemini (Selección)",
  a = { "<cmd>CodeCompanionChat Add<cr>", "Añadir Código al Chat" },
  i = { "<cmd>CodeCompanion<cr>", "Modificar Selección (Inline)" },
}

-- Búsqueda en Modo Visual (Snacks)
vm["s"] = {
  name = "Search",
  g = { function() Snacks.picker.grep_word() end, "Buscar Selección (Grep)" },
}


-- Molten en Modo Visual (Evaluar selección exacta)
vm["M"] = {
  name = "Math & Jupyter (Molten)",
  e = { ":<C-u>MoltenEvaluateVisual<CR>gv", "Evaluar Selección" },
}

-- =================================================================
-- 🎨 REFINAMIENTO VISUAL FINAL
-- =================================================================
local function set_visual_polish()
  local hl = vim.api.nvim_set_hl

  -- Paleta Material Deep Ocean
  local material_blue = "#82aaff"
  local material_cyan = "#89ddff"
  local material_bg_alt = "#1a1e2a"

  -- Fix Cabeceras Markdown
  hl(0, "RenderMarkdownH1", { fg = material_blue, bold = true })
  hl(0, "RenderMarkdownH1Bg", { bg = "#1e2332", fg = material_blue, bold = true })
  hl(0, "RenderMarkdownH2", { fg = material_cyan, bold = true })
  hl(0, "RenderMarkdownH3", { fg = "#addbff", bold = true })

  -- Treesitter Highlighting
  hl(0, "@markup.heading.1.markdown", { fg = material_blue, bold = true })
  hl(0, "@markup.heading.2.markdown", { fg = material_cyan, bold = true })

  -- UI y Ventanas
  hl(0, "NormalFloat", { bg = "none" })
  hl(0, "FloatBorder", { fg = material_blue, bg = "none" })
  hl(0, "CursorLine", { bg = material_bg_alt })
  hl(0, "CursorLineNr", { fg = "#c792ea", bold = true })

  hl(0, "BlinkCmpMenu", { bg = "#0d1117" })
  hl(0, "DiagnosticVirtualTextError", { fg = "#ff5370", italic = true })
end

-- Ejecución y Autocmds
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_visual_polish })
set_visual_polish()

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})


-- Configuración para tu LSP personalizado de Spoon
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local jar_path = vim.fn.expand("~/dev/spoon-jdt-lsp/target/spoon-jdt-lsp-1.0-SNAPSHOT-jar-with-dependencies.jar")

    -- Comando para iniciar el servidor
    local cmd = { "java", "-jar", jar_path }

    -- Iniciar el cliente LSP
    vim.lsp.start({
      name = "spoon-lsp",
      cmd = cmd,
      root_dir = vim.fs.dirname(vim.fs.find({ 'pom.xml', '.git' }, { upward = true })[1]),
      settings = {},
    })
  end,
})
