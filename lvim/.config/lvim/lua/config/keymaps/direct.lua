-- =================================================================
-- ⚡ KEYMAPS DIRECTOS DE PRODUCTIVIDAD (Sin <leader>)
-- =================================================================
local map = require("config.utils").map


-- 🔄 Navegación Rápida entre Buffers
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Buffer Anterior" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Siguiente Buffer" })

-- 🪟 Redimensionar Ventanas con Ctrl+Flechas
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Aumentar Alto Ventana" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Reducir Alto Ventana" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Reducir Ancho Ventana" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Aumentar Ancho Ventana" })

-- 📐 Mover Líneas con Alt+j/k (Normal e Insert)
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Mover Línea Abajo" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Mover Línea Arriba" })
map("i", "<A-j>", "<Esc><cmd>m .+1<cr>==gi", { desc = "Mover Línea Abajo" })
map("i", "<A-k>", "<Esc><cmd>m .-2<cr>==gi", { desc = "Mover Línea Arriba" })

-- 💾 Guardado Rápido
map("n", "<C-s>", "<cmd>w<cr>", { desc = "Guardar Archivo" })
map("i", "<C-s>", "<Esc><cmd>w<cr>gi", { desc = "Guardar Archivo" })

-- 🎯 Flash.nvim: Treesitter Select (complementa el 's' ya mapeado)
map("n", "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
map("x", "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
map("o", "r", function() require("flash").remote() end, { desc = "Flash Remote" })

-- 🩺 LINTERS Y DIAGNÓSTICOS (Navegación Rápida Estilo 2026)
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Siguiente Diagnóstico" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Diagnóstico Anterior" })
map("n", "gl", vim.diagnostic.open_float, { desc = "Ver Diagnóstico Flotante" })

-- 🔀 Navegación de Hunks Git con ] y [
map("n", "]h", "<cmd>Gitsigns next_hunk<cr>", { desc = "Siguiente Hunk Git" })
map("n", "[h", "<cmd>Gitsigns prev_hunk<cr>", { desc = "Hunk Git Anterior" })

-- 📋 Mejor Manejo del Portapapeles
map("x", "p", '"_dP', { desc = "Pegar sin Perder Registro" })

-- 🔲 Mantener Selección al Indentar
map("v", "<", "<gv", { desc = "Desindentar y Mantener Selección" })
map("v", ">", ">gv", { desc = "Indentar y Mantener Selección" })

-- 📐 Mover Selección Visual con Alt+j/k
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Mover Selección Abajo" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Mover Selección Arriba" })

-- 🧹 Limpiar Resaltado de Búsqueda
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Limpiar Resaltado de Búsqueda" })

-- 📋 Seleccionar Todo
map("n", "<C-a>", "ggVG", { desc = "Seleccionar Todo" })

-- ❌ Cerrar / Salir
map("n", "<C-q>", "<cmd>confirm q<cr>", { desc = "Cerrar (con confirmación)" })

-- 📋 Copiar Selección al Portapapeles del Sistema
map("v", "<C-c>", '"+y', { desc = "Copiar al Portapapeles del Sistema" })

-- 📄 Duplicar Línea
map("n", "<S-A-j>", "<cmd>t.<cr>", { desc = "Duplicar Línea Abajo" })
map("n", "<S-A-k>", "<cmd>t -1<cr>", { desc = "Duplicar Línea Arriba" })
map("i", "<S-A-j>", "<Esc><cmd>t.<cr>gi", { desc = "Duplicar Línea Abajo" })
map("i", "<S-A-k>", "<Esc><cmd>t -1<cr>gi", { desc = "Duplicar Línea Arriba" })

-- 🧭 Centrar al Navegar (Productividad)
map("n", "<C-d>", "<C-d>zz", { desc = "Media Página Abajo (Centrado)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Media Página Arriba (Centrado)" })
map("n", "n", "nzzzv", { desc = "Siguiente Búsqueda (Centrado)" })
map("n", "N", "Nzzzv", { desc = "Búsqueda Anterior (Centrado)" })
