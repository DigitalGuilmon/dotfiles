# This is a sample commands.py.  You can add your own commands here.
#
# Please refer to commands_full.py for all the default commands and a complete
# documentation.  Do NOT add them all here, or you may end up with defunct
# commands when upgrading ranger.

# A simple command for demonstration purposes follows.
# -----------------------------------------------------------------------------

from __future__ import absolute_import, division, print_function

# You can import any python module as needed.
import os

# You always need to import ranger.api.commands here to get the Command class:
from ranger.api.commands import Command


# Any class that is a subclass of "Command" will be integrated into ranger as a
# command.  Try typing ":my_edit<ENTER>" in ranger!
class my_edit(Command):
    # The so-called doc-string of the class will be visible in the built-in
    # help that is accessible by typing "?c" inside ranger.
    """:my_edit <filename>

    A sample command for demonstration purposes that opens a file in an editor.
    """

    # The execute method is called when you run this command in ranger.
    def execute(self):
        # self.arg(1) is the first (space-separated) argument to the function.
        # This way you can write ":my_edit somefilename<ENTER>".
        if self.arg(1):
            # self.rest(1) contains self.arg(1) and everything that follows
            target_filename = self.rest(1)
        else:
            # self.fm is a ranger.core.filemanager.FileManager object and gives
            # you access to internals of ranger.
            # self.fm.thisfile is a ranger.container.file.File object and is a
            # reference to the currently selected file.
            target_filename = self.fm.thisfile.path

        # This is a generic function to print text in ranger.
        self.fm.notify("Let's edit the file " + target_filename + "!")

        # Using bad=True in fm.notify allows you to print error messages:
        if not os.path.exists(target_filename):
            self.fm.notify("The given file does not exist!", bad=True)
            return

        # This executes a function from ranger.core.acitons, a module with a
        # variety of subroutines that can help you construct commands.
        # Check out the source, or run "pydoc ranger.core.actions" for a list.
        self.fm.edit_file(target_filename)

    # The tab method is called when you press tab, and should return a list of
    # suggestions that the user will tab through.
    # tabnum is 1 for <TAB> and -1 for <S-TAB> by default
    def tab(self, tabnum):
        # This is a generic tab-completion function that iterates through the
        # content of the current directory.
        return self._tab_directory_content()


import os
import platform
import shlex
import shutil
import subprocess
from ranger.api.commands import Command


def _first_available(*commands):
    for command in commands:
        if shutil.which(command):
            return command
    return None


def _notify_missing_dependency(fm, dependency):
    fm.notify(f"Required dependency not found: {dependency}", bad=True)


def _expand_path(path):
    return os.path.expandvars(os.path.expanduser(path))


class fzf_select(Command):
    """
    :fzf_select
    Busca archivos usando fzf y cambia el foco de Ranger al seleccionado.
    """

    def execute(self):
        import subprocess
        import os.path

        # comando fzf (puedes añadir --hidden para ver archivos ocultos)
        command = "find . -maxdepth 4 -not -path '*/.*' | fzf +m"
        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.decode("utf-8").rstrip("\n"))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class z(Command):
    """
    :z <path>
    Usa zoxide para saltar a una carpeta visitada frecuentemente.
    """

    def execute(self):
        import subprocess

        arg = self.rest(1)
        if arg:
            process = subprocess.Popen(["zoxide", "query", arg], stdout=subprocess.PIPE)
            stdout, _ = process.communicate()
            if process.returncode == 0:
                directory = stdout.decode("utf-8").strip()
                self.fm.cd(directory)


class fzf_content_search(Command):
    """
    :fzf_content_search
    Busca texto dentro de los archivos usando ripgrep y fzf.
    """

    def execute(self):
        import subprocess
        import os.path

        # Comando potente: busca texto y muestra preview del archivo
        command = "rg --column --line-number --no-heading --color=always --smart-case . | fzf --ansi --delimiter : --preview 'bat --style=numbers --color=always --highlight-line {2} {1}'"
        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            parts = stdout.decode("utf-8").split(":")
            if len(parts) >= 1:
                target_file = os.path.abspath(parts[0])
                self.fm.select_file(target_file)
                # Opcional: abrir en la línea específica si tu editor lo soporta


class spotlight(Command):
    """
    :spotlight <query>
    Usa el motor de búsqueda de Apple para saltar a archivos.
    """

    def execute(self):
        query = self.rest(1)
        if not query:
            self.fm.notify("Usage: :spotlight <query>", bad=True)
            return

        if shutil.which("mdfind"):
            search_command = f"mdfind {shlex.quote(query)}"
        elif shutil.which("plocate"):
            search_command = f"plocate -i {shlex.quote(query)}"
        elif shutil.which("locate"):
            search_command = f"locate -i {shlex.quote(query)}"
        elif shutil.which("fd"):
            search_command = f"fd -HI {shlex.quote(query)} {shlex.quote(_expand_path('~'))}"
        else:
            pattern = shlex.quote(f"*{query}*")
            search_command = f"find {shlex.quote(_expand_path('~'))} -iname {pattern}"

        command = f"{search_command} | fzf"
        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            selected = stdout.decode("utf-8").rstrip("\n")
            if os.path.isdir(selected):
                self.fm.cd(selected)
            elif selected:
                self.fm.select_file(selected)


class smart_open(Command):
    """:smart_open
    Abre el archivo seleccionado con el opener nativo del sistema.
    """

    def execute(self):
        selected = self.fm.thistab.get_selection() or [self.fm.thisfile]
        if not selected:
            self.fm.notify("No file selected", bad=True)
            return

        opener = _first_available("open", "xdg-open")
        if not opener:
            _notify_missing_dependency(self.fm, "open/xdg-open")
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
            command = ["mv"] + paths + [_expand_path("~/.Trash")]
        else:
            _notify_missing_dependency(self.fm, "trash utility")
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
        copy_command = _first_available("pbcopy", "wl-copy", "xclip", "xsel")

        if not shutil.which("tesseract"):
            _notify_missing_dependency(self.fm, "tesseract")
            return

        if not copy_command:
            _notify_missing_dependency(self.fm, "clipboard utility")
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
        copy.communicate()
        ocr_returncode = ocr.wait()

        if ocr_returncode != 0 or copy.returncode != 0:
            self.fm.notify("Failed to copy OCR to clipboard", bad=True)
            return

        self.fm.notify("OCR copied to clipboard")
