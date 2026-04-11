import os
import shlex

from ranger.api.commands import Command

from .base import (
    choose_with_fzf,
    copy_to_clipboard,
    current_directory,
    git_root,
    open_shell_in_terminal,
    path_relative_to,
    selected_paths,
)


def selected_or_current_paths(fm):
    paths = selected_paths(fm)
    if paths:
        return paths
    return [current_directory(fm)]


class copy_relative_path(Command):
    """:copy_relative_path
    Copia al portapapeles las rutas seleccionadas relativas al directorio actual.
    """

    def execute(self):
        cwd = current_directory(self.fm)
        payload = "\n".join(path_relative_to(path, cwd) for path in selected_or_current_paths(self.fm))
        if copy_to_clipboard(self.fm, payload):
            self.fm.notify("Relative path copied")


class copy_repo_path(Command):
    """:copy_repo_path
    Copia al portapapeles las rutas seleccionadas relativas al root del repo git.
    """

    def execute(self):
        first_path = selected_or_current_paths(self.fm)[0]
        root = git_root(first_path)
        if not root:
            self.fm.notify("Current selection is not inside a git repository", bad=True)
            return

        payload = "\n".join(path_relative_to(path, root) for path in selected_or_current_paths(self.fm))
        if copy_to_clipboard(self.fm, payload):
            self.fm.notify("Repo path copied")


class git_file_actions(Command):
    """:git_file_actions
    Abre acciones git orientadas al archivo o proyecto actual.
    """

    def execute(self):
        target = selected_or_current_paths(self.fm)[0]
        root = git_root(target)
        if not root:
            self.fm.notify("Current selection is not inside a git repository", bad=True)
            return

        relative_path = path_relative_to(target, root)
        choice = choose_with_fzf(
            self.fm,
            [
                "lazygit (repo)",
                "git diff -- current path",
                "git log -- current path",
                "copy HEAD:path",
            ],
            "git> ",
        )
        if not choice:
            return

        if choice == "lazygit (repo)":
            open_shell_in_terminal(self.fm, root, "lazygit", os.path.basename(root) or "git")
            return

        if choice == "git diff -- current path":
            command = f"git diff -- {shlex.quote(relative_path)} | ${{PAGER:-less}}"
            open_shell_in_terminal(self.fm, root, command, "git-diff")
            return

        if choice == "git log -- current path":
            command = f"git log --stat --follow -- {shlex.quote(relative_path)} | ${{PAGER:-less}}"
            open_shell_in_terminal(self.fm, root, command, "git-log")
            return

        if choice == "copy HEAD:path":
            if copy_to_clipboard(self.fm, f"HEAD:{relative_path}"):
                self.fm.notify("HEAD:path copied")
