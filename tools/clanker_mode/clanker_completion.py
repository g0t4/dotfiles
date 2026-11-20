"""Completion candidates for Clanker's shell and sub-REPL interfaces."""

from __future__ import annotations

import json
import shlex
from pathlib import Path

from prompt_toolkit.completion import Completer, Completion

ROOT_COMMANDS = {
    "manage": "Saved context and conversation controls",
    "--help": "Show Clanker usage",
    "--list": "List saved conversations",
    "--save": "Save the active conversation",
    "--rename": "Rename and save the active conversation",
    "--restore": "Restore a saved conversation",
    "--compact": "Compact active model context",
    "--rollback": "Roll back the prior context turn",
    "--clear": "Clear active model context",
    "--trace": "Print this shell's trace path",
}

MANAGE_COMMANDS = {
    "list": "List saved conversations",
    "save": "Save the active conversation",
    "rename": "Rename and save the active conversation",
    "restore": "Restore a saved conversation",
    "compact": "Compact active model context",
    "rollback": "Roll back the prior context turn",
    "clear": "Clear active model context",
    "trace": "Print this shell's trace path",
}

REPL_COMMANDS = {
    "/list": "List saved conversations",
    "/save": "Save the active conversation",
    "/rename": "Rename and save the active conversation",
    "/restore": "Restore a saved conversation",
    "/compact": "Compact active model context",
    "/rollback": "Roll back the prior context turn",
    "/clear": "Clear active model context",
    "/trace": "Print this shell's trace path",
    "/help": "Show sub-REPL controls",
    "/exit": "Leave the sub-REPL",
}


def saved_snapshots(directory):
    directory = Path(directory)
    snapshots = []
    if directory.is_dir():
        for path in directory.glob("*.json"):
            try:
                snapshots.append(json.loads(path.read_text()))
            except (OSError, json.JSONDecodeError, TypeError):
                continue
    return sorted(
        snapshots,
        key=lambda item: (
            item.get("restore_count", 0),
            item.get("last_restored_at") or item.get("updated_at", ""),
        ),
        reverse=True,
    )


def _matches(value, prefix, *, substring=False):
    value = value.casefold()
    prefix = prefix.strip("'\"").casefold()
    return prefix in value if substring else value.startswith(prefix)


def shell_candidates(args, arg_index, prefix, saved_directory):
    """Return `(value, display, description)` candidates for native Xonsh."""
    if arg_index == 1:
        return [
            (value, value, description)
            for value, description in ROOT_COMMANDS.items()
            if _matches(value, prefix)
        ]
    if len(args) > 1 and args[1] == "manage" and arg_index == 2:
        return [
            (value, value, description)
            for value, description in MANAGE_COMMANDS.items()
            if _matches(value, prefix)
        ]
    restore = (
        len(args) > 1
        and args[1] == "--restore"
        and arg_index == 2
        or len(args) > 2
        and args[1:3] == ["manage", "restore"]
        and arg_index == 3
    )
    if not restore:
        return []
    return [
        (
            shlex.quote(snapshot["title"]),
            snapshot["title"],
            f"{snapshot.get('restore_count', 0)} restores",
        )
        for snapshot in saved_snapshots(saved_directory)
        if _matches(snapshot["title"], prefix, substring=True)
    ]


class ClankerReplCompleter(Completer):
    def __init__(self, saved_directory):
        self.saved_directory = Path(saved_directory)

    def get_completions(self, document, complete_event):
        text = document.text_before_cursor
        if not text.startswith("/"):
            return
        if text.startswith("/restore "):
            prefix = text[len("/restore ") :]
            for snapshot in saved_snapshots(self.saved_directory):
                title = snapshot["title"]
                if _matches(title, prefix, substring=True):
                    yield Completion(
                        title,
                        start_position=-len(prefix),
                        display=title,
                        display_meta=f"{snapshot.get('restore_count', 0)} restores",
                    )
            return
        if " " in text:
            return
        for value, description in REPL_COMMANDS.items():
            if _matches(value, text):
                yield Completion(
                    value,
                    start_position=-len(text),
                    display_meta=description,
                )
