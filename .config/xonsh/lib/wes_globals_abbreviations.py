"""Global interactive abbreviations migrated from Fish."""

from __future__ import annotations

import re

from wes_abbreviations import abbr


EMOJI_ABBREVIATIONS = {
    "love": "❤️",
    "fire": "🔥",
    "smile": "😊",
    "thumbsup": "👍",
    "party": "🥳",
    "coffee": "☕",
    "check": "✅",
    "star": "⭐",
    "rocket": "🚀",
    "grin": "😁",
    "think": "🤔",
    "clap": "👏",
    "ok": "👌",
    "shrug": "🤷",
    "wave": "👋",
    "music": "🎵",
    "sun": "☀️",
    "moon": "🌙",
}


def _numbered_command(command, *, pipe=False):
    def expand(_context, match):
        assert match is not None
        prefix = "| " if pipe else ""
        return f"{prefix}{command} -{match.group(1)}"

    return expand


def register_globals_abbreviations():
    for trigger, emoji in EMOJI_ABBREVIATIONS.items():
        abbr(trigger, emoji)

    for trigger, replacement in {
        "pgr": "| rg_grep -i",
        "pgrv": "| rg_grep -i --invert-match",
        "pjq": "| jq .",
        "pjqr": "| jq -r .",
        "pjqj": "| jq --join-output .",
        "pbat": "| bat -pl",
        "phelp": "| bat -pl help",
        "pini": "| bat -pl ini",
        "pmd": "| bat -pl md",
        "prb": "| bat -pl rb",
        "psh": "| bat -pl sh",
        "pxml": "| bat -pl xml",
        "pyml": "| bat -pl yml",
        "plua": "| bat -pl lua",
        "ppy": "| bat -pl py",
        "puniq": "| sort | uniq -c",
        "psort": "| sort -h",
        "errout": "2>&1",
        "pwc": "| wordcount",
        "hC": "| hexdump -C",
        "pcp": "| pbcopy",
    }.items():
        abbr(trigger, replacement, position="anywhere")

    abbr(
        re.compile(r"ph(\d+)"),
        _numbered_command("head", pipe=True),
        position="anywhere",
    )
    abbr(re.compile(r"h(\d+)"), _numbered_command("head"))
    abbr(
        re.compile(r"pt(\d+)"),
        _numbered_command("tail", pipe=True),
        position="anywhere",
    )

    abbr(
        "px",
        "| xargs --verbose -I_ -- % _",
        position="anywhere",
        cursor_marker="%",
    )
    abbr(
        "pxi",
        "| xargs --interactive -I_ -- % _",
        position="anywhere",
        cursor_marker="%",
    )
    abbr("xargs", "gxargs")
