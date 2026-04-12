#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--menu-id")
    parser.add_argument("--prompt", default="")
    parser.add_argument("--theme")
    parser.add_argument("--no-history", action="store_true")
    args, extra = parser.parse_known_args()
    if extra and extra[0] == "--":
        extra = extra[1:]
    return args, extra


def history_path(menu_id: str) -> Path:
    digest = hashlib.sha256(menu_id.encode("utf-8")).hexdigest()[:16]
    cache_dir = Path.home() / ".cache" / "rofi-frequent"
    cache_dir.mkdir(parents=True, exist_ok=True)
    return cache_dir / f"{digest}.json"


def load_history(path: Path) -> dict[str, dict[str, int]]:
    if not path.exists():
        return {}
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def save_history(path: Path, data: dict[str, dict[str, int]]) -> None:
    temp_path = path.with_suffix(".tmp")
    with temp_path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, sort_keys=True)
    os.replace(temp_path, path)


def visible_label(option: str) -> str:
    return option.split("\0", 1)[0]


def reorder_options(options: list[str], history: dict[str, dict[str, int]]) -> list[str]:
    ranked = []
    for index, option in enumerate(options):
        label = visible_label(option)
        entry = history.get(label, {})
        ranked.append(
            (
                -(int(entry.get("count", 0))),
                -(int(entry.get("last_used", 0))),
                index,
                option,
            )
        )
    ranked.sort()
    return [option for _, _, _, option in ranked]


def main():
    args, extra = parse_args()
    options = sys.stdin.read().splitlines()
    history_enabled = bool(args.menu_id) and not args.no_history and bool(options)

    ordered_options = options
    path = None
    history = {}
    if history_enabled:
        path = history_path(args.menu_id)
        history = load_history(path)
        ordered_options = reorder_options(options, history)

    command = ["rofi", "-dmenu", "-p", args.prompt]
    if args.theme:
        command += ["-theme", args.theme]
    command += extra

    result = subprocess.run(
        command,
        input="\n".join(ordered_options),
        capture_output=True,
        text=True,
        check=False,
    )

    if result.stdout:
        sys.stdout.write(result.stdout)
    if result.stderr:
        sys.stderr.write(result.stderr)

    selection = result.stdout.rstrip("\n")
    if (
        result.returncode == 0
        and history_enabled
        and selection
        and path is not None
    ):
        entry = history.get(selection, {})
        history[selection] = {
            "count": int(entry.get("count", 0)) + 1,
            "last_used": time.time_ns(),
        }
        save_history(path, history)

    raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
