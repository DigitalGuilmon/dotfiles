#!/usr/bin/env python3

from pathlib import Path


CONFIG_DIR = Path(__file__).resolve().parent
SECTION_FILES = [
    CONFIG_DIR / "rc.d/00-settings.conf",
    CONFIG_DIR / "rc.d/10-navigation-and-files.conf",
    CONFIG_DIR / "rc.d/20-tabs-sorting-and-modes.conf",
    CONFIG_DIR / "rc.d/90-custom.conf",
]
OUTPUT_FILE = CONFIG_DIR / "rc.conf"


def render_section(path: Path) -> str:
    title = f"# --- {path.name} ---"
    body = path.read_text().rstrip()
    return f"{title}\n{body}\n"


def main() -> None:
    content = [
        "# -----------------------------------------------------------------------------",
        "# Generated from ranger/.config/ranger/rc.d/*.conf",
        "# Do not edit manually. Run ranger/.config/ranger/build_rc.py",
        "# -----------------------------------------------------------------------------",
        "",
    ]
    content.extend(render_section(path) for path in SECTION_FILES)
    OUTPUT_FILE.write_text("\n".join(content).rstrip() + "\n")


if __name__ == "__main__":
    main()
