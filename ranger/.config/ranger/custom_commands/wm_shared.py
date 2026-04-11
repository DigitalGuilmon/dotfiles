from ranger.api.commands import Command

from .base import run_wm_dispatch, run_wm_script


class projects_menu(Command):
    """:projects_menu
    Abre el menu compartido de proyectos.
    """

    def execute(self):
        run_wm_dispatch(self.fm, "projects-menu")


class clipboard_menu(Command):
    """:clipboard_menu
    Abre el menu compartido de portapapeles.
    """

    def execute(self):
        run_wm_dispatch(self.fm, "clipboard-menu")


class files_menu(Command):
    """:files_menu
    Abre el menu compartido de archivos.
    """

    def execute(self):
        run_wm_dispatch(self.fm, "files-menu")


class system_info_menu(Command):
    """:system_info_menu
    Abre el menu compartido de informacion del sistema.
    """

    def execute(self):
        run_wm_dispatch(self.fm, "system-info")


class session_menu(Command):
    """:session_menu
    Abre el menu compartido de sesion.
    """

    def execute(self):
        run_wm_dispatch(self.fm, "session-menu")


class workspace_menu(Command):
    """:workspace_menu
    Abre el menu compartido de workspaces.
    """

    def execute(self):
        run_wm_dispatch(self.fm, "workspace-menu")


class scratchpad_menu(Command):
    """:scratchpad_menu
    Abre el menu compartido de scratchpads.
    """

    def execute(self):
        run_wm_dispatch(self.fm, "scratchpad-menu")


class multimedia_menu(Command):
    """:multimedia_menu
    Abre el menu compartido de multimedia.
    """

    def execute(self):
        run_wm_dispatch(self.fm, "multimedia-menu")


class todo_menu(Command):
    """:todo_menu
    Abre el menu compartido de TODOs.
    """

    def execute(self):
        run_wm_script(self.fm, "productivity/todo.hs")


class keybind_cheatsheet(Command):
    """:keybind_cheatsheet
    Abre el cheatsheet compartido de keybinds.
    """

    def execute(self):
        run_wm_script(self.fm, "system/keybind_cheatsheet.hs")


class calculator_menu(Command):
    """:calculator_menu
    Abre la calculadora compartida.
    """

    def execute(self):
        run_wm_script(self.fm, "productivity/calculator.hs")


class english_menu(Command):
    """:english_menu
    Abre el menu compartido de ingles.
    """

    def execute(self):
        run_wm_script(self.fm, "productivity/english.hs")
