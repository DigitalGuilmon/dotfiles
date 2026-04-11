import os
import shlex
import shutil
import subprocess

from ranger.api.commands import Command

from .base import expand_path


class fzf_select(Command):
    """
    :fzf_select
    Busca archivos usando fzf y cambia el foco de Ranger al seleccionado.
    """

    def execute(self):
        command = "find . -maxdepth 4 -not -path '*/.*' | fzf +m"
        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
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
        command = (
            "rg --column --line-number --no-heading --color=always --smart-case . | "
            "fzf --ansi --delimiter : "
            "--preview 'bat --style=numbers --color=always --highlight-line {2} {1}'"
        )
        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            parts = stdout.decode("utf-8").split(":")
            if len(parts) >= 1:
                target_file = os.path.abspath(parts[0])
                self.fm.select_file(target_file)


class spotlight(Command):
    """
    :spotlight <query>
    Busca archivos usando el indexador disponible en el sistema.
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
            search_command = f"fd --hidden --no-ignore {shlex.quote(query)} {shlex.quote(expand_path('~'))}"
        else:
            pattern = shlex.quote(f"*{query}*")
            search_command = f"find {shlex.quote(expand_path('~'))} -iname {pattern}"

        command = f"{search_command} | fzf"
        fzf = self.fm.execute_command(command, stdout=subprocess.PIPE)
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            selected = stdout.decode("utf-8").rstrip("\n")
            if os.path.isdir(selected):
                self.fm.cd(selected)
            elif selected:
                self.fm.select_file(selected)
