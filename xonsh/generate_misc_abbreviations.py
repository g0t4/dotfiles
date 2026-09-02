#!/usr/bin/env python3
"""Generate focused Xonsh modules from the historical Fish misc file."""

from __future__ import annotations

import re
import shlex
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "fish/load_last_interactive_only/misc-specific.fish"
TARGET_DIR = ROOT / ".config/xonsh/lib"


@dataclass(frozen=True)
class Module:
    name: str
    ranges: tuple[tuple[int, int], ...]

    def contains(self, line_number: int) -> bool:
        return any(start <= line_number <= end for start, end in self.ranges)

    @property
    def target(self) -> Path:
        return TARGET_DIR / f"wes_{self.name}_abbreviations.py"


MODULES = (
    Module("system_services", ((47, 217),)),
    Module("kubernetes", ((218, 769),)),
    Module("processes", ((770, 1176), (2772, 2812))),
    Module("cloud_ai", ((1357, 1672), (2813, 3132), (3309, 3383), (3502, 3512))),
    Module("media", ((1673, 2030), (2337, 2460), (2627, 2652), (3133, 3161), (3438, 3501))),
    Module("packages_hardware", ((1177, 1356), (2031, 2336), (2461, 2771))),
    Module("misc", ((3162, 3308), (3384, 3437), (3513, 3623))),
)

SKIPPED_ABBREVIATION_LINES = {
    # Linux alternatives are folded into platform-aware macOS declarations.
    866,
    867,
    871,
    872,
    # Exact duplicate in the Fish source.
    1528,
    # Templates executed by build_abbrs_for_filetype, not literal triggers.
    955,
    959,
    962,
    965,
    # Templates executed once per ~/.local/share/devtools/*.log file.
    2876,
    2879,
    2882,
    # Folded into the platform-aware Linux lsusb declaration.
    2747,
}

UNSUPPORTED_ABBREVIATION_LINES = {
    3307: "uses Fish loop syntax to print the current shell PATH",
    3439: "changes the current shell PATH",
}

REPLACEMENTS = {
    '"$(_repo_root)"': "$(_repo_root)",
    "$sed_cmd": "$XONSH_SED_COMMAND",
    "$man_cmd": "$XONSH_MAN_COMMAND",
    "$_ls_http": "http paxy.lan:8016",
    "$_ls_prompt": "prompt='what is 11*2'",
    "$_ls_messages": 'messages:=[ {"role": "user", "content": "what is 11*2"} ]',
    "$_ollama_serve": "ollama serve 2>&1 | bat -pp -l log",
    "$sse_jq": "sed -E 's/^[^{]*//' | jq",
}

NAME_OVERRIDES = {
    # The Fish source accidentally declares man7 three times; preserve intent.
    2207: "man8",
    2208: "man9",
}

PLATFORM_REPLACEMENTS = {
    855: ("pkill -9 -ilf", "pkill -9 -if"),
    856: ("pkill -9 -U $USER -ilf", "pkill -9 -U $USER -if"),
    2735: ("system_profiler SPUSBDataType", "lsusb -tv"),
}

# Fish-native implementations whose Xonsh ports intentionally use structured
# helpers instead of reproducing the source command literally.
MIGRATION_REPLACEMENTS = {
    783: "_abbr_list --any '%'",
    784: "_abbr_list --prefix '%'",
}


def parse_abbreviation(line_number: int, line: str):
    # Fish accepts backslash-escaped single quotes inside single-quoted text;
    # POSIX shlex does not. Protect those two legacy awk expressions while
    # tokenizing, then restore the intended quote character.
    quote_placeholder = "__WES_FISH_SINGLE_QUOTE__"
    tokens = [
        token.replace(quote_placeholder, "'")
        for token in shlex.split(
            line.replace("\\'", quote_placeholder), comments=True, posix=True
        )
    ]
    options: dict[str, str | bool] = {}
    remaining: list[str] = []
    index = 1
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            remaining.extend(tokens[index + 1 :])
            break
        if token in ("--set-cursor",):
            options["cursor"] = True
            index += 1
        elif token in ("--add", "-a", "--command", "--function", "--regex", "--position"):
            options[token.lstrip("-").replace("a", "add", 1) if token == "-a" else token[2:]] = tokens[index + 1]
            index += 2
        elif token.startswith("--position="):
            options["position"] = token.partition("=")[2]
            index += 1
        else:
            remaining.append(token)
            index += 1

    name = str(options.get("add") or remaining.pop(0))
    return line_number, name, " ".join(remaining), options


def declaration(line_number, name, replacement, options):
    name = NAME_OVERRIDES.get(line_number, name)
    trigger = f"re.compile({options['regex']!r})" if "regex" in options else repr(name)
    if line_number in UNSUPPORTED_ABBREVIATION_LINES:
        replacement_expression = (
            f"unsupported_abbreviation({name!r}, "
            f"{UNSUPPORTED_ABBREVIATION_LINES[line_number]!r})"
        )
    elif line_number in PLATFORM_REPLACEMENTS:
        replacement_expression = f"platform_abbreviation{PLATFORM_REPLACEMENTS[line_number]!r}"
    elif "function" in options:
        replacement_expression = f"fish_abbreviation({options['function']!r})"
    else:
        replacement = MIGRATION_REPLACEMENTS.get(line_number, replacement)
        for old, new in REPLACEMENTS.items():
            replacement = replacement.replace(old, new)
        replacement_expression = repr(replacement)
    arguments = ["registry", trigger, replacement_expression]
    if options.get("position") == "anywhere" or options.get("command"):
        arguments.append('position="anywhere"')
    if options.get("command"):
        command = options["command"]
        command_expression = {
            "$man_cmd": "MAN_COMMAND",
            "$sed_cmd": "SED_COMMAND",
        }.get(command, repr(command))
        arguments.append(f"commands=({command_expression},)")
    if options.get("cursor") and replacement.count("%") == 1:
        arguments.append('cursor_marker="%"')
    return f"    abbr({', '.join(arguments)})  # Fish line {line_number}"


def generate(module: Module) -> str:
    declarations = []
    functions = []
    for line_number, line in enumerate(SOURCE.read_text().splitlines(), 1):
        if not module.contains(line_number):
            continue
        if (
            re.match(r"^\s*abbr(?:\s|$)", line)
            and line_number not in SKIPPED_ABBREVIATION_LINES
        ):
            declarations.append(declaration(*parse_abbreviation(line_number, line)))
        function_match = re.match(r"^\s*function\s+([^\s]+)", line)
        if function_match:
            functions.append((function_match.group(1), line_number))

    title = module.name.replace("_", " ").title()
    function_name = f"register_{module.name}_abbreviations"
    declaration_text = "\n".join(declarations)
    stdlib_imports = []
    if "re.compile" in declaration_text:
        stdlib_imports.append("import re")
    platform_constants = []
    if "MAN_COMMAND" in declaration_text:
        platform_constants.append(
            'MAN_COMMAND = "gman" if platform.system() == "Darwin" else "man"'
        )
    if "SED_COMMAND" in declaration_text:
        platform_constants.append(
            'SED_COMMAND = "gsed" if platform.system() == "Darwin" else "sed"'
        )
    if platform_constants:
        stdlib_imports.insert(0, "import platform")
    stdlib_imports_text = (
        "\n".join(stdlib_imports) + "\n\n" if stdlib_imports else ""
    )
    platform_constants_text = (
        "\n".join(platform_constants) + "\n\n" if platform_constants else ""
    )
    bridge_names = [
        name
        for name in (
            "fish_abbreviation",
            "platform_abbreviation",
            "unsupported_abbreviation",
        )
        if name in declaration_text
    ]
    bridge_import = ""
    if bridge_names:
        names = "\n".join(f"    {name}," for name in bridge_names)
        bridge_import = (
            "from wes_misc_abbreviation_bridge import (\n" + names + "\n)\n"
        )
    header = f'''\
"""{title} abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

{stdlib_imports_text}\
from wes_abbreviations import AbbreviationRegistry, abbr
{bridge_import}

{platform_constants_text}\
FISH_FUNCTIONS = (
'''
    function_inventory = "".join(
        f"    {name!r},  # Fish line {line_number}\n"
        for name, line_number in functions
    )
    footer = f'''\
)


def {function_name}(registry: AbbreviationRegistry):
'''
    return header + function_inventory + footer + declaration_text + "\n"


def generate_all() -> dict[Path, str]:
    return {module.target: generate(module) for module in MODULES}


if __name__ == "__main__":
    for target, content in generate_all().items():
        target.write_text(content)
