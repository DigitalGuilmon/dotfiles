import os
import shlex

from ranger.api.commands import Command

from .base import (
    current_directory,
    first_available,
    notify_missing_dependency,
    open_shell_in_terminal,
    project_root,
    selected_path,
    session_name_from_path,
)


class dev_open_in_lvim(Command):
    """:dev_open_in_lvim
    Abre archivo/carpeta actual en lvim (fallback nvim/vim).
    """

    def execute(self):
        editor = first_available("lvim", "nvim", "vim")
        if not editor:
            notify_missing_dependency(self.fm, "lvim/nvim/vim")
            return

        target = selected_path(self.fm)
        self.fm.execute_command([editor, target])


class dev_tmux_lvim(Command):
    """:dev_tmux_lvim
    Abre el proyecto actual en una ventana de tmux con lvim.
    """

    def execute(self):
        if not first_available("tmux"):
            notify_missing_dependency(self.fm, "tmux")
            return

        editor = first_available("lvim", "nvim", "vim")
        if not editor:
            notify_missing_dependency(self.fm, "lvim/nvim/vim")
            return

        target = selected_path(self.fm)
        root = project_root(target)
        relative_target = os.path.relpath(target, root)
        if relative_target == ".":
            relative_target = ""

        launch = f"cd {shlex.quote(root)} && {shlex.quote(editor)}"
        if relative_target:
            launch = f"{launch} {shlex.quote(relative_target)}"

        if os.getenv("TMUX"):
            self.fm.execute_command(
                ["tmux", "new-window", "-c", root, "-n", os.path.basename(root), launch]
            )
            return

        session_name = session_name_from_path(root)
        self.fm.execute_command(["tmux", "new-session", "-A", "-s", session_name, "-c", root, launch])


class dev_tmux_split_lvim(Command):
    """:dev_tmux_split_lvim
    Divide el pane actual y abre el archivo/carpeta en lvim.
    """

    def execute(self):
        if not os.getenv("TMUX"):
            self.fm.notify("Requires running inside tmux", bad=True)
            return

        editor = first_available("lvim", "nvim", "vim")
        if not editor:
            notify_missing_dependency(self.fm, "lvim/nvim/vim")
            return

        target = selected_path(self.fm)
        root = project_root(target)
        relative_target = os.path.relpath(target, root)
        if relative_target == ".":
            relative_target = ""

        launch = f"cd {shlex.quote(root)} && {shlex.quote(editor)}"
        if relative_target:
            launch = f"{launch} {shlex.quote(relative_target)}"

        self.fm.execute_command(["tmux", "split-window", "-h", "-c", root, launch])


class dev_open_in_lvim_root(Command):
    """:dev_open_in_lvim_root
    Abre el archivo/carpeta actual en lvim usando el root del proyecto como cwd.
    """

    def execute(self):
        editor = first_available("lvim", "nvim", "vim")
        if not editor:
            notify_missing_dependency(self.fm, "lvim/nvim/vim")
            return

        target = selected_path(self.fm)
        root = project_root(target)
        relative_target = os.path.relpath(target, root)
        if relative_target == ".":
            relative_target = ""

        command = f"cd {shlex.quote(root)} && {shlex.quote(editor)}"
        if relative_target:
            command = f"{command} {shlex.quote(relative_target)}"

        self.fm.execute_command(["sh", "-lc", command])


class dev_tmux_project(Command):
    """:dev_tmux_project
    Abre o reutiliza una sesión tmux del proyecto actual con lvim.
    """

    def execute(self):
        dev_tmux_lvim.execute(self)


class open_terminal_here(Command):
    """:open_terminal_here
    Abre una terminal en el directorio actual de ranger.
    """

    def execute(self):
        cwd = current_directory(self.fm)
        open_shell_in_terminal(self.fm, cwd, "${SHELL:-bash}", os.path.basename(cwd) or "shell")
