"""Global interactive abbreviations migrated from Fish."""

from __future__ import annotations

import re

from wes_abbreviations import abbr


EMOJI_ABBREVIATIONS = {
    "love": "❤️",
    "chefs_kiss": "👨‍🍳💋",
    "cigarette": "🚬",
    "hot!": "🚬 🚬 🚬 🚬 🚬 🚬 🚬",
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
    # more for quick reactions to awesome work by my agent
    "fireworks": "🎆",

    # Exceptional work
    "genius": "🧠💡",
    "masterpiece": "🎨🏆",
    "perfection": "🤌💋",
    "legendary": "👑🏆🔥",
    "holy_shit": "🤯🤯🤯",
    "standing_ovation": "👏👏👏👏👏",
    "mic_drop": "🎤💥",
    "big_brain": "🧠🧠🧠",
    "wizard": "🧙‍♂️✨",
    "beautiful": "🥹❤️",
    "nailed_it": "💅'ed it",
    "flawless": "💎✨",

    # Victory celebrations
    "boom": "💥💥💥",
    "ship_it": "🚢✅",
    "victory": "🏆🥇",
    "jackpot": "🎰💰",
    "hell_yes": "🔥🚀❤️",
    "dance": "💃🕺🎉",
    "unstoppable": "🚂💨",

    # Clever discoveries
    "aha": "💡👀",
    "detective": "🕵️🔎",
    "interesting": "🧐🔬",
    "mind_blown": "🤯💥",
    "plot_twist": "👀🍿",
    "sneaky": "🥷✨",
    "galaxy_brain": "🧠🌌",

    # Questionable decisions
    "sus": "🤨📸",
    "wat": "👁️👄👁️",
    # TODO! look into why delta shows some diff than my nerdfont terminal combo in neovim
    #  like here it shows male symbol next to this:
    #  yes... zero width joiner (ZWJ) .. FML
    "facepalm": "🤦‍♂️",
    "bruh": "💀",
    "uh_oh": "😬🚨",
    "yikes": "🫣💥",
    "nope": "🙅‍♂️❌",
    "side_eye": "👀",
    "confused": "❓🤨",

    # Spectacular failures
    "exploded": "💥🔥💀",
    "rip": "🪦💐",
    "dumpster_fire": "🗑️🔥",
    "clown": "🤡",
    "what_the_fuck": "🤬⁉️",
    "try_again": "🔄🛠️",
    "back_to_work": "🫵💻",
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
        "hC": "| hexyl -C",
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
