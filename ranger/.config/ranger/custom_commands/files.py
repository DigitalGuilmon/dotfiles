import os
import platform
import shutil
import subprocess
import tempfile
from pathlib import Path

from ranger.api.commands import Command

from .base import (
    current_directory,
    first_available,
    expand_path,
    notify_missing_dependency,
    selected_paths,
)


class my_edit(Command):
    """:my_edit <filename>

    A sample command for demonstration purposes that opens a file in an editor.
    """

    def execute(self):
        if self.arg(1):
            target_filename = self.rest(1)
        else:
            target_filename = self.fm.thisfile.path

        self.fm.notify("Let's edit the file " + target_filename + "!")

        if not os.path.exists(target_filename):
            self.fm.notify("The given file does not exist!", bad=True)
            return

        self.fm.edit_file(target_filename)

    def tab(self, tabnum):
        return self._tab_directory_content()


class smart_open(Command):
    """:smart_open
    Abre el archivo seleccionado con el opener nativo del sistema.
    """

    def execute(self):
        selected = self.fm.thistab.get_selection() or [self.fm.thisfile]
        if not selected:
            self.fm.notify("No file selected", bad=True)
            return

        opener = first_available("open", "xdg-open")
        if not opener:
            notify_missing_dependency(self.fm, "open/xdg-open")
            return

        paths = [f.path for f in selected]
        self.fm.execute_command([opener] + paths)


class smart_trash(Command):
    """:smart_trash
    Envía archivos seleccionados a la papelera con fallback multiplataforma.
    """

    def execute(self):
        selected = self.fm.thistab.get_selection() or [self.fm.thisfile]
        if not selected:
            self.fm.notify("No file selected", bad=True)
            return

        paths = [f.path for f in selected]
        if shutil.which("trash-put"):
            command = ["trash-put"] + paths
        elif shutil.which("gio"):
            command = ["gio", "trash"] + paths
        elif shutil.which("kioclient5"):
            command = ["kioclient5", "move"] + paths + ["trash:/"]
        elif platform.system() == "Darwin":
            command = ["mv"] + paths + [expand_path("~/.Trash")]
        else:
            notify_missing_dependency(self.fm, "trash utility")
            return

        self.fm.execute_command(command)


class ocr_to_clipboard(Command):
    """:ocr_to_clipboard
    Extrae texto con OCR y lo copia al portapapeles con fallback por plataforma.
    """

    def execute(self):
        if not self.fm.thisfile:
            self.fm.notify("No file selected", bad=True)
            return

        target_file = self.fm.thisfile.path
        copy_command = first_available("pbcopy", "wl-copy", "xclip", "xsel")

        if not shutil.which("tesseract"):
            notify_missing_dependency(self.fm, "tesseract")
            return

        if not copy_command:
            notify_missing_dependency(self.fm, "clipboard utility")
            return

        copy_invocations = {
            "pbcopy": ["pbcopy"],
            "wl-copy": ["wl-copy"],
            "xclip": ["xclip", "-selection", "clipboard"],
            "xsel": ["xsel", "--clipboard", "--input"],
        }

        ocr = subprocess.Popen(
            ["tesseract", target_file, "stdout"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        copy = subprocess.Popen(
            copy_invocations[copy_command],
            stdin=ocr.stdout,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if ocr.stdout is not None:
            ocr.stdout.close()
        copy.communicate()
        ocr_returncode = ocr.wait()

        if ocr_returncode != 0 or copy.returncode != 0:
            self.fm.notify("Failed to copy OCR to clipboard", bad=True)
            return

        self.fm.notify("OCR copied to clipboard")


def archive_output_dir(path):
    archive_path = Path(path)
    name = archive_path.name
    for suffix in [".tar.gz", ".tar.bz2", ".tar.xz", ".tar.zst", ".tgz", ".tbz2", ".txz"]:
        if name.endswith(suffix):
            return archive_path.parent / name[: -len(suffix)]
    return archive_path.parent / archive_path.stem


class extract_here_smart(Command):
    """:extract_here_smart
    Extrae cada archivo seleccionado en una carpeta vecina con el nombre del archivo.
    """

    def execute(self):
        paths = selected_paths(self.fm)
        if not paths:
            self.fm.notify("No archive selected", bad=True)
            return

        extractor = first_available("atool", "bsdtar")
        if not extractor:
            notify_missing_dependency(self.fm, "atool/bsdtar")
            return

        for path in paths:
            output_dir = archive_output_dir(path)
            output_dir.mkdir(exist_ok=True)
            if extractor == "atool":
                command = ["atool", "--extract-to", str(output_dir), "--each", path]
            else:
                command = ["bsdtar", "-xf", path, "-C", str(output_dir)]
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if result.returncode != 0:
                self.fm.notify(f"Failed to extract {os.path.basename(path)}", bad=True)
                return

        self.fm.reload_cwd()
        self.fm.notify("Archives extracted")


class bulk_rename_lvim(Command):
    """:bulk_rename_lvim
    Renombra la selección editando sus nombres en lvim.
    """

    def execute(self):
        paths = selected_paths(self.fm)
        if not paths:
            self.fm.notify("No files selected", bad=True)
            return

        editor = first_available("lvim", "nvim", "vim")
        if not editor:
            notify_missing_dependency(self.fm, "lvim/nvim/vim")
            return

        original_names = [os.path.basename(path) for path in paths]
        with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".txt") as temp_file:
            temp_path = temp_file.name
            temp_file.write("\n".join(original_names) + "\n")

        try:
            result = subprocess.run([editor, temp_path])
            if result.returncode != 0:
                self.fm.notify("Rename aborted", bad=True)
                return

            with open(temp_path, "r", encoding="utf-8") as handle:
                new_names = [line.rstrip("\n") for line in handle.readlines()]

            if len(new_names) != len(paths):
                self.fm.notify("Rename list length changed", bad=True)
                return

            if any(not name for name in new_names):
                self.fm.notify("Empty file names are not allowed", bad=True)
                return

            seen = set()
            for path, new_name in zip(paths, new_names):
                target = str(Path(path).with_name(new_name))
                if target in seen:
                    self.fm.notify("Duplicate rename target detected", bad=True)
                    return
                seen.add(target)

            for path, new_name in zip(paths, new_names):
                target = str(Path(path).with_name(new_name))
                if path != target:
                    os.rename(path, target)

            self.fm.reload_cwd()
            self.fm.notify("Bulk rename complete")
        finally:
            os.unlink(temp_path)


class downloads_recent(Command):
    """:downloads_recent
    Abre el menu de descargas recientes compartido.
    """

    def execute(self):
        script = expand_path("~/.config/wm-shared/scripts/bin/network/download.hs")
        if not os.path.exists(script):
            self.fm.notify(f"wm-shared script not found: {script}", bad=True)
            return
        self.fm.execute_command([script])
