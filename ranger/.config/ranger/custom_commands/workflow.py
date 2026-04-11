import json
import os
import re
import subprocess
from pathlib import Path

from ranger.api.commands import Command

from .base import (
    change_directory,
    choose_with_fzf,
    current_directory,
    file_mime,
    first_available,
    notify_missing_dependency,
    open_shell_in_terminal,
    project_root,
    selected_paths,
    shlex_quote,
)


def selected_or_current_paths(fm):
    paths = selected_paths(fm)
    if paths:
        return paths
    return [current_directory(fm)]


class places_menu(Command):
    """:places_menu
    Navega a carpetas personales frecuentes desde un menu.
    """

    def execute(self):
        choices = [
            ("Home", "~"),
            ("Downloads", os.getenv("XDG_DOWNLOAD_DIR", "~/Downloads")),
            ("Documents", os.getenv("XDG_DOCUMENTS_DIR", "~/Documents")),
            ("Desktop", os.getenv("XDG_DESKTOP_DIR", "~/Desktop")),
            ("Projects", os.getenv("RANGER_PROJECTS_DIR", "~/Projects")),
            ("dotfiles", "~/dotfiles"),
            ("Notes", os.getenv("RANGER_NOTES_DIR", "~/dev/vault/notes")),
            ("dev", "~/dev"),
            ("Pictures", os.getenv("XDG_PICTURES_DIR", "~/Pictures")),
            ("Screenshots", f"{os.getenv('XDG_PICTURES_DIR', '~/Pictures')}/Screenshots"),
            ("Wallpapers", f"{os.getenv('XDG_PICTURES_DIR', '~/Pictures')}/Wallpapers"),
            ("Music", os.getenv("XDG_MUSIC_DIR", "~/Music")),
            ("Videos", os.getenv("XDG_VIDEOS_DIR", "~/Videos")),
        ]
        mapping = {label: path for label, path in choices}
        selection = choose_with_fzf(self.fm, [label for label, _ in choices], "places> ")
        if selection:
            change_directory(self.fm, mapping[selection])


class run_project_task(Command):
    """:run_project_task
    Descubre tareas del proyecto actual y las ejecuta en una terminal.
    """

    def execute(self):
        root = project_root(selected_or_current_paths(self.fm)[0])
        tasks = discover_project_tasks(root)
        if not tasks:
            self.fm.notify("No project tasks found", bad=True)
            return

        selection = choose_with_fzf(self.fm, list(tasks.keys()), "task> ")
        if selection:
            open_shell_in_terminal(self.fm, root, tasks[selection], os.path.basename(root) or "task")


def discover_project_tasks(root):
    tasks = {}
    root_path = Path(root)

    if ((root_path / "justfile").exists() or (root_path / ".justfile").exists()) and first_available("just"):
        try:
            output = subprocess.check_output(["just", "--summary"], cwd=root, text=True, stderr=subprocess.DEVNULL)
            for name in output.split():
                tasks[f"just {name}"] = f"just {name}"
        except subprocess.CalledProcessError:
            pass

    if (root_path / "Makefile").exists() and first_available("make"):
        try:
            output = subprocess.check_output(["make", "-qp"], cwd=root, text=True, stderr=subprocess.DEVNULL)
            for line in output.splitlines():
                if ":" in line and not line.startswith(("\t", "#", ".")):
                    target = line.split(":", 1)[0].strip()
                    if target and "%" not in target and " " not in target:
                        tasks.setdefault(f"make {target}", f"make {target}")
        except subprocess.CalledProcessError:
            pass

    package_json = root_path / "package.json"
    if package_json.exists() and first_available("npm"):
        try:
            data = json.loads(package_json.read_text(encoding="utf-8"))
            for name in (data.get("scripts") or {}).keys():
                tasks[f"npm run {name}"] = f"npm run {name}"
        except json.JSONDecodeError:
            pass

    return dict(sorted(tasks.items()))


class normalize_filenames(Command):
    """:normalize_filenames
    Normaliza nombres de archivos seleccionados a kebab-case ASCII.
    """

    def execute(self):
        paths = selected_paths(self.fm)
        if not paths:
            self.fm.notify("No files selected", bad=True)
            return

        targets = {}
        for path in paths:
            source = Path(path)
            normalized = normalize_name(source.name)
            target = str(source.with_name(normalized))
            if target in targets.values():
                self.fm.notify("Normalization would create duplicate names", bad=True)
                return
            targets[path] = target

        for path, target in targets.items():
            if path != target:
                os.replace(path, target)

        self.fm.reload_cwd()
        self.fm.notify("Filenames normalized")


def normalize_name(name):
    stem = Path(name).stem
    suffix = "".join(Path(name).suffixes)
    normalized = re.sub(r"[^a-z0-9]+", "-", stem.lower()).strip("-")
    return f"{normalized or 'file'}{suffix.lower()}"


class move_selection_by_type(Command):
    """:move_selection_by_type
    Mueve la seleccion a subcarpetas segun el tipo de archivo.
    """

    def execute(self):
        paths = selected_paths(self.fm)
        if not paths:
            self.fm.notify("No files selected", bad=True)
            return

        cwd = Path(current_directory(self.fm))
        for path in paths:
            source = Path(path)
            target_dir = cwd / classify_path(source)
            target_dir.mkdir(exist_ok=True)
            target = target_dir / source.name
            try:
                if source.resolve() == target.resolve():
                    continue
            except FileNotFoundError:
                pass
            os.replace(source, target)

        self.fm.reload_cwd()
        self.fm.notify("Selection moved by type")


def classify_path(path):
    mime = file_mime(str(path))
    if mime.startswith("image/"):
        return "Images"
    if mime.startswith("video/"):
        return "Videos"
    if mime.startswith("audio/"):
        return "Audio"
    if mime == "application/pdf" or mime.startswith("text/"):
        return "Documents"
    if "zip" in mime or "compressed" in mime or path.suffix.lower() in {".tar", ".gz", ".xz", ".bz2", ".7z", ".rar", ".zip"}:
        return "Archives"
    return "Other"


class open_with_context(Command):
    """:open_with_context
    Abre la seleccion con el opener mas adecuado.
    """

    def execute(self):
        paths = selected_or_current_paths(self.fm)
        first_path = paths[0]
        mime = file_mime(first_path)
        options = []
        if mime.startswith("image/"):
            options.extend([("nsxiv", "nsxiv"), ("feh", "feh")])
        if mime.startswith(("video/", "audio/")):
            options.append(("mpv", "mpv"))
        if mime == "application/pdf":
            options.extend([("zathura", "zathura"), ("evince", "evince")])
        options.extend([("lvim", "lvim"), ("xdg-open", "xdg-open")])

        available = [(label, cmd) for label, cmd in options if first_available(cmd)]
        if not available:
            self.fm.notify("No contextual opener available", bad=True)
            return

        selection = choose_with_fzf(self.fm, [label for label, _ in available], "open> ")
        if not selection:
            return
        command = next(cmd for label, cmd in available if label == selection)
        self.fm.execute_command([command] + paths)


class file_diagnostics(Command):
    """:file_diagnostics
    Ejecuta diagnosticos utiles sobre la seleccion o el directorio actual.
    """

    def execute(self):
        choice = choose_with_fzf(
            self.fm,
            [
                "file info for selection",
                "sha256 for selection",
                "largest files in cwd",
                "broken symlinks in cwd",
                "empty files in cwd",
            ],
            "diag> ",
        )
        if not choice:
            return

        cwd = current_directory(self.fm)
        paths = selected_or_current_paths(self.fm)
        quoted_paths = " ".join(shlex_quote(path) for path in paths)

        if choice == "file info for selection":
            command = f"file --dereference --mime -- {quoted_paths} && printf '\\n' && stat -- {quoted_paths} | ${{PAGER:-less}}"
            open_shell_in_terminal(self.fm, cwd, command, "file-info")
            return
        if choice == "sha256 for selection":
            command = f"sha256sum -- {quoted_paths} | ${{PAGER:-less}}"
            open_shell_in_terminal(self.fm, cwd, command, "sha256")
            return
        if choice == "largest files in cwd":
            command = "find . -type f -printf '%s\\t%p\\n' | sort -nr | head -50 | numfmt --field=1 --to=iec | ${PAGER:-less}"
            open_shell_in_terminal(self.fm, cwd, command, "largest-files")
            return
        if choice == "broken symlinks in cwd":
            command = "find . -xtype l | ${PAGER:-less}"
            open_shell_in_terminal(self.fm, cwd, command, "broken-links")
            return
        if choice == "empty files in cwd":
            command = "find . -type f -empty | ${PAGER:-less}"
            open_shell_in_terminal(self.fm, cwd, command, "empty-files")
