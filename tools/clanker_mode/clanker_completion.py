"""Completion candidates for Clanker's shell and sub-REPL interfaces."""

from __future__ import annotations

from pathlib import Path

from prompt_toolkit.completion import Completer, Completion

from clanker_saved import SavedConversations

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
    "--messages": "Dump active conversation JSON",
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
    "messages": "Dump active conversation JSON",
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
    "/messages": "Dump active conversation JSON",
    "/help": "Show sub-REPL controls",
    "/exit": "Leave the sub-REPL",
}


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
            repr(snapshot["title"]),
            snapshot["title"],
            f"{snapshot.get('restore_count', 0)} restores",
        )
        for snapshot in SavedConversations(saved_directory).list()
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
            for snapshot in SavedConversations(self.saved_directory).list():
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
