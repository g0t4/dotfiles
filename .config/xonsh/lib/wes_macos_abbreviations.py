"""macOS abbreviations migrated from fish/load_last_interactive_only/macos-specific.fish."""

from __future__ import annotations

from wes_abbreviations import abbr


def register_macos_abbreviations():
    # Fish lines 10-18.  The clipboard pipeline uses Xonsh's $() subprocess
    # syntax so pasted passwords are not limited by `security -w`.
    abbr(
        "securityf",
        "security find-generic-password -w -s % -a ",
        cursor_marker="%",
    )
    abbr(
        "securityrm",
        "security delete-generic-password -s % -a ",
        cursor_marker="%",
    )
    abbr(
        "securitya",
        "security add-generic-password -U -X $(pbpaste | xxd -p | tr -d '\\n') -s % -a ",
        cursor_marker="%",
    )
