import os
import re
import shlex
import shutil
import subprocess
from pathlib import Path


def first_available(*commands):
    for command in commands:
        if shutil.which(command):
            return command
    return None


def notify_missing_dependency(fm, dependency):
    fm.notify(f"Required dependency not found: {dependency}", bad=True)


def expand_path(path):
    return os.path.expandvars(os.path.expanduser(path))


def first_existing_path(*paths):
    for path in paths:
        expanded = expand_path(path)
        if os.path.exists(expanded):
            return expanded
    return None


def current_directory(fm):
    if fm.thisdir:
        return fm.thisdir.path
    return os.getcwd()


def selected_entries(fm):
    selection = list(fm.thistab.get_selection() or [])
    if selection:
        return selection
    if fm.thisfile:
        return [fm.thisfile]
    return []


def selected_paths(fm):
    return [entry.path for entry in selected_entries(fm)]


def selected_path(fm):
    paths = selected_paths(fm)
    if paths:
        return paths[0]
    return current_directory(fm)


def git_root(path):
    base_path = path if os.path.isdir(path) else os.path.dirname(path)
    try:
        root = subprocess.check_output(
            ["git", "-C", base_path, "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        if root:
            return root
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    return None


def project_root(path):
    base_path = path if os.path.isdir(path) else os.path.dirname(path)
    root = git_root(path)
    if root:
        return root
    return base_path or os.getcwd()


def change_directory(fm, path):
    expanded = expand_path(path)
    if not os.path.exists(expanded):
        fm.notify(f"Path not found: {expanded}", bad=True)
        return False
    fm.cd(expanded)
    return True


def path_relative_to(path, root):
    return os.path.relpath(path, root)


def session_name_from_path(path):
    session_name = re.sub(r"[^A-Za-z0-9_-]", "_", os.path.basename(path) or "dev")
    return session_name[:60]


def clipboard_invocation():
    command = first_available("pbcopy", "wl-copy", "xclip", "xsel")
    if command == "pbcopy":
        return ["pbcopy"]
    if command == "wl-copy":
        return ["wl-copy"]
    if command == "xclip":
        return ["xclip", "-selection", "clipboard"]
    if command == "xsel":
        return ["xsel", "--clipboard", "--input"]
    return None


def copy_to_clipboard(fm, text):
    invocation = clipboard_invocation()
    if not invocation:
        notify_missing_dependency(fm, "clipboard utility")
        return False
    process = subprocess.Popen(invocation, stdin=subprocess.PIPE, text=True)
    process.communicate(text)
    if process.returncode != 0:
        fm.notify("Failed to copy to clipboard", bad=True)
        return False
    return True


def choose_with_fzf(fm, options, prompt):
    if not first_available("fzf"):
        notify_missing_dependency(fm, "fzf")
        return None
    process = subprocess.Popen(
        ["fzf", "--prompt", prompt],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    stdout, _ = process.communicate("\n".join(options) + "\n")
    if process.returncode == 0:
        return stdout.rstrip("\n")
    return None


def wm_shared_bin_dir():
    return Path(expand_path("~/.config/wm-shared/scripts/bin"))


def run_wm_script(fm, relative_path, *args):
    script_path = wm_shared_bin_dir() / relative_path
    if not script_path.exists():
        fm.notify(f"wm-shared script not found: {script_path}", bad=True)
        return False
    fm.execute_command([str(script_path), *args])
    return True


def run_wm_dispatch(fm, action_name):
    return run_wm_script(fm, "dispatch.hs", action_name)


def open_shell_in_terminal(fm, cwd, shell_command, title):
    if os.getenv("TMUX"):
        fm.execute_command(["tmux", "new-window", "-c", cwd, "-n", title, shell_command])
        return True

    terminal = first_available("ghostty", "x-terminal-emulator")
    if not terminal:
        notify_missing_dependency(fm, "ghostty/x-terminal-emulator")
        return False

    command = f"cd {shlex_quote(cwd)} && {shell_command}; exec $SHELL"
    if terminal == "ghostty":
        fm.execute_command([terminal, "-e", "sh", "-lc", command])
    else:
        fm.execute_command([terminal, "-e", "sh", "-lc", command])
    return True


def shlex_quote(value):
    return subprocess.list2cmdline([value]) if os.name == "nt" else shlex.quote(value)


def file_mime(path):
    try:
        return subprocess.check_output(
            ["file", "--dereference", "--brief", "--mime-type", "--", path],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""
