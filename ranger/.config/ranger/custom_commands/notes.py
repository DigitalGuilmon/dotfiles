import os
import re
from datetime import datetime
from pathlib import Path

from ranger.api.commands import Command

from .base import (
    change_directory,
    choose_with_fzf,
    copy_to_clipboard,
    expand_path,
    first_available,
    notify_missing_dependency,
    selected_paths,
)


def notes_root():
    return Path(expand_path(os.getenv("RANGER_NOTES_DIR", "~/dev/vault/notes")))


def notes_assets_dir():
    return Path(expand_path(os.getenv("RANGER_NOTES_ASSETS_DIR", str(notes_root() / "assets"))))


def slugify(value):
    clean = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    return clean or "note"


class notes_actions(Command):
    """:notes_actions
    Ejecuta acciones de notas sobre la seleccion actual.
    """

    def execute(self):
        choice = choose_with_fzf(
            self.fm,
            [
                "new note from selection",
                "move selection to notes assets",
                "copy markdown links for selection",
                "open notes root",
            ],
            "notes> ",
        )
        if not choice:
            return

        if choice == "new note from selection":
            create_note_from_selection(self.fm)
        elif choice == "move selection to notes assets":
            move_selection_to_notes_assets(self.fm)
        elif choice == "copy markdown links for selection":
            copy_markdown_links(self.fm)
        elif choice == "open notes root":
            change_directory(self.fm, str(notes_root()))


def create_note_from_selection(fm):
    paths = selected_paths(fm)
    base_name = os.path.basename(paths[0]) if paths else "quick-note"
    target_dir = notes_root()
    target_dir.mkdir(parents=True, exist_ok=True)

    slug = slugify(Path(base_name).stem)
    filename = f"{datetime.now().strftime('%Y-%m-%d-%H%M%S')}-{slug}.md"
    note_path = target_dir / filename
    source_lines = "\n".join(f"- {path}" for path in paths) if paths else "-"
    note_path.write_text(
        f"# {Path(base_name).stem}\n\n## Source\n{source_lines}\n\n## Notes\n",
        encoding="utf-8",
    )

    editor = first_available("lvim", "nvim", "vim")
    if not editor:
        notify_missing_dependency(fm, "lvim/nvim/vim")
        return
    fm.execute_command([editor, str(note_path)])


def move_selection_to_notes_assets(fm):
    paths = selected_paths(fm)
    if not paths:
        fm.notify("No files selected", bad=True)
        return

    target_dir = notes_assets_dir()
    target_dir.mkdir(parents=True, exist_ok=True)

    for path in paths:
        target = target_dir / os.path.basename(path)
        os.replace(path, target)

    fm.reload_cwd()
    fm.notify("Selection moved to notes assets")


def copy_markdown_links(fm):
    paths = selected_paths(fm)
    if not paths:
        fm.notify("No files selected", bad=True)
        return

    payload = "\n".join(
        f"[{os.path.basename(path)}](file://{path})" for path in paths
    )
    if copy_to_clipboard(fm, payload):
        fm.notify("Markdown links copied")
