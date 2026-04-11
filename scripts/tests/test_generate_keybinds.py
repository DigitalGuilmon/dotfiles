from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


def load_generate_keybinds_module():
    repo_root = Path(__file__).resolve().parents[2]
    script_path = repo_root / "wm-shared/.config/wm-shared/scripts/bin/system/generate_keybinds.py"
    spec = importlib.util.spec_from_file_location("generate_keybinds", script_path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


generate_keybinds = load_generate_keybinds_module()


class GenerateKeybindsLvimTests(unittest.TestCase):
    def test_render_lvim_from_repo_keybinds_contains_expected_bindings(self) -> None:
        repo_root = Path(__file__).resolve().parents[2]
        keybinds_path = repo_root / "wm-shared/.config/wm-shared/keybinds.yml"
        config = generate_keybinds.yaml.safe_load(keybinds_path.read_text(encoding="utf-8"))
        rendered = generate_keybinds.render_lvim(config)

        self.assertIn('u.wk_assign("m", "Y", {', rendered)
        self.assertIn('u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowQuery<cr>")', rendered)
        self.assertIn('u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianQuickSwitch<cr>")', rendered)
        self.assertIn('u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianDailies<cr>")', rendered)
        self.assertIn('u.lazy_wrap({ "obsidian.nvim" }, "<cmd>ObsidianLinks<cr>")', rendered)
        self.assertIn('require("config.env").obsidian_templates_dir()', rendered)
        self.assertIn('u.wk_assign("m", "n", {', rendered)
        self.assertIn('"<cmd>Noice last<cr>"', rendered)
        self.assertIn('"<cmd>Noice all<cr>"', rendered)
        self.assertIn('"<cmd>LvimAIStatus<cr>"', rendered)
        self.assertIn('"<cmd>LvimAISelectProvider<cr>"', rendered)
        self.assertIn('"<cmd>LvimSetupInfo<cr>"', rendered)
        self.assertIn('"<cmd>CoverageSummary<cr>"', rendered)
        self.assertIn('u.lazy_wrap({ "rainbow_csv" }, "<cmd>RainbowCellGoRight<cr>")', rendered)
        generated_path = repo_root / "lvim/.config/lvim/lua/config/keymaps/generated.lua"
        self.assertEqual(rendered, generated_path.read_text(encoding="utf-8"))

    def test_render_lvim_resolves_semantic_actions_and_filetype_maps(self) -> None:
        rendered = generate_keybinds.render_lvim(
            {
                "lvim": {
                    "plugin_aliases": {"blink": "blink.cmp"},
                    "items": [
                        {
                            "kind": "group",
                            "writer": "assign",
                            "target": "m",
                            "key": "D",
                            "name": "Database",
                            "entries": [
                                {
                                    "key": "u",
                                    "action": "dbui-toggle",
                                    "description": "Toggle DB UI",
                                }
                            ],
                        },
                        {
                            "kind": "direct_map",
                            "filetype": "pdsl",
                            "mode": "i",
                            "lhs": "<C-Space>",
                            "action": "pdsl-completion",
                            "description": "PDSL completion",
                        },
                        {
                            "kind": "binding",
                            "target": "m",
                            "key": "o",
                            "action": "obsidian-template-picker",
                            "description": "Template",
                        },
                    ],
                    "keymaps": [],
                }
            }
        )

        self.assertIn('u.lazy_wrap({ "vim-dadbod-ui" }, "<cmd>DBUIToggle<cr>")', rendered)
        self.assertIn('require("config.env").obsidian_templates_dir()', rendered)
        self.assertIn(
            'u.filetype_direct_map("pdsl", "i", "<C-Space>", u.lazy_wrap({ "blink.cmp" }, function() require("config.pdsl").show_completion() end), "PDSL completion")',
            rendered,
        )

    def test_render_lvim_expands_plugin_aliases(self) -> None:
        rendered = generate_keybinds.render_lvim(
            {
                "lvim": {
                    "plugin_aliases": {"flash": "flash.nvim"},
                    "items": [
                        {
                            "kind": "direct_map",
                            "mode": "n",
                            "lhs": "s",
                            "plugins": ["flash"],
                            "lua": 'function() require("flash").jump() end',
                            "description": "Flash",
                        }
                    ],
                    "keymaps": [],
                }
            }
        )

        self.assertIn('u.direct_map("n", "s", u.lazy_wrap({ "flash.nvim" }, function() require("flash").jump() end), "Flash")', rendered)

    def test_render_lvim_rejects_unknown_action(self) -> None:
        with self.assertRaisesRegex(ValueError, "acción LVim no soportada"):
            generate_keybinds.render_lvim(
                {
                    "lvim": {
                        "items": [
                            {
                                "kind": "binding",
                                "target": "m",
                                "key": "x",
                                "action": "missing-action",
                                "description": "Broken",
                            }
                        ],
                        "keymaps": [],
                    }
                }
            )

    def test_render_lvim_rejects_invalid_filetype(self) -> None:
        with self.assertRaisesRegex(ValueError, "filetype LVim inválido"):
            generate_keybinds.render_lvim(
                {
                    "lvim": {
                        "items": [
                            {
                                "kind": "direct_map",
                                "filetype": 42,
                                "mode": "i",
                                "lhs": "<C-Space>",
                                "action": "pdsl-completion",
                                "description": "Broken",
                            }
                        ],
                        "keymaps": [],
                    }
                }
            )


if __name__ == "__main__":
    unittest.main()
