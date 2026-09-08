#!/usr/bin/env python3
"""Sync the small audio, HTTP, network, gitignore, and GH abbreviation collections."""

import re
import shlex
from pathlib import Path

from generate_misc_abbreviations import parse_abbreviation

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "audio_video": "fish/load_last_interactive_only/audio-vido-specific.fish",
    "http": "fish/load_last_interactive_only/curl_http.fish",
    "network": "fish/load_last_interactive_only/network-specific.fish",
    "gitignore": "fish/load_last_interactive_only/gitignore-wrappers.fish",
    "gh": "zsh/compat_fish/gh.zsh",
}


def generate(domain):
    source = SOURCES[domain]
    declarations = []
    functions = []
    for number, line in enumerate((ROOT / source).read_text().splitlines(), 1):
        if line.startswith("function "):
            functions.append(line.split()[1])
        if line.startswith("_create_abbr_ff_help_filter "):
            _, kind, name = shlex.split(line)
            trigger = f"ff_help_filter_{kind}_{name}"
            replacement = f"ffmpeg --help filter={name} && open https://ffmpeg.org/ffmpeg-filters.html#{name}"
            declarations.append(f"    abbr({trigger!r}, {replacement!r})  # Source line {number}")
        if not line.startswith("abbr "):
            continue
        _, name, replacement, options = parse_abbreviation(number, line)
        # This is the declaration template inside the Fish factory above.
        if name == "$abbr_name":
            continue
        replacement = replacement.replace("$_show_prefix", "ffprobe -loglevel warning ")
        value = (f"audio_abbreviation({options['function']!r}, cursor={bool(options.get('cursor'))!r})"
                 if "function" in options else repr(replacement))
        arguments = [repr(name), value]
        if "command" in options:
            arguments += ['position="anywhere"', f"commands=({options['command']!r},)"]
        if options.get("cursor") and "function" not in options:
            arguments += ['cursor_marker="%"']
        declarations.append(f"    abbr({', '.join(arguments)})  # Source line {number}")
    imports = "from wes_abbreviations import abbr\n"
    if any("audio_abbreviation(" in line for line in declarations):
        imports += "from wes_daily_tool_bridges import audio_abbreviation\n"
    return (f'"""Generated from {source}; edit Fish/Zsh and rerun the generator."""\n\n'
            + imports + f"\nSOURCE_FUNCTIONS = {tuple(functions)!r}\n\n\n"
            + f"def register_{domain}_abbreviations():\n" + "\n".join(declarations) + "\n")


if __name__ == "__main__":
    for domain in SOURCES:
        (ROOT / f".config/xonsh/lib/wes_{domain}_tool_abbreviations.py").write_text(generate(domain))
