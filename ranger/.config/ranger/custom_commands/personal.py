import os

from ranger.api.commands import Command

from .base import change_directory, expand_path, first_existing_path


def env_or_default(env_name, default_path):
    return expand_path(os.getenv(env_name, default_path))


def open_personal_path(fm, *candidates):
    resolved = first_existing_path(*candidates)
    if not resolved:
        fm.notify(f"Path not found: {expand_path(candidates[0])}", bad=True)
        return
    change_directory(fm, resolved)


class go_home(Command):
    def execute(self):
        open_personal_path(self.fm, "~")


class go_downloads(Command):
    def execute(self):
        open_personal_path(self.fm, os.getenv("XDG_DOWNLOAD_DIR", "~/Downloads"))


class go_documents(Command):
    def execute(self):
        open_personal_path(self.fm, os.getenv("XDG_DOCUMENTS_DIR", "~/Documents"))


class go_desktop(Command):
    def execute(self):
        open_personal_path(self.fm, os.getenv("XDG_DESKTOP_DIR", "~/Desktop"))


class go_projects(Command):
    def execute(self):
        open_personal_path(self.fm, os.getenv("RANGER_PROJECTS_DIR", "~/Projects"), "~/dev")


class go_dotfiles(Command):
    def execute(self):
        open_personal_path(self.fm, "~/dotfiles")


class go_notes(Command):
    def execute(self):
        open_personal_path(self.fm, os.getenv("RANGER_NOTES_DIR", "~/dev/vault/notes"), "~/Notes")


class go_dev(Command):
    def execute(self):
        open_personal_path(self.fm, "~/dev")


class go_pictures(Command):
    def execute(self):
        open_personal_path(self.fm, os.getenv("XDG_PICTURES_DIR", "~/Pictures"))


class go_screenshots(Command):
    def execute(self):
        pictures_dir = os.getenv("XDG_PICTURES_DIR", "~/Pictures")
        open_personal_path(self.fm, f"{pictures_dir}/Screenshots")


class go_wallpapers(Command):
    def execute(self):
        pictures_dir = os.getenv("XDG_PICTURES_DIR", "~/Pictures")
        open_personal_path(self.fm, f"{pictures_dir}/Wallpapers", "~/Videos/Wallpapers")


class go_music(Command):
    def execute(self):
        open_personal_path(self.fm, os.getenv("XDG_MUSIC_DIR", "~/Music"))


class go_videos(Command):
    def execute(self):
        open_personal_path(self.fm, os.getenv("XDG_VIDEOS_DIR", "~/Videos"))
