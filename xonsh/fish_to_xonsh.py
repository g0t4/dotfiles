"""Reusable machinery for generating Xonsh abbreviation modules from Fish."""

from __future__ import annotations

from dataclasses import dataclass
import re
import shlex
from pathlib import Path
from typing import Callable


DeclarationFactory = Callable[[str, str, dict[str, str | bool]], str]


def parse_abbreviation(line: str, VALUE_SUBSTITUTIONS:dict[str, str]|None = None):
    """Parse one Fish ``abbr`` declaration without losing Fish quoting."""
    # Fish accepts backslash-escaped single quotes inside single-quoted text;
    # POSIX shlex does not. Protect those legacy awk expressions while
    # tokenizing, then restore the intended quote character.
    quote_placeholder = "__WES_FISH_SINGLE_QUOTE__"
    tokens = [
        token.replace(quote_placeholder, "'")
        for token in shlex.split(
            line.replace("\\'", quote_placeholder), comments=True, posix=True
        )
    ]
    # import rich
    # rich.print(tokens)
    #
    options: dict[str, str | bool] = {}
    remaining: list[str] = []
    index = 1
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            remaining.extend(tokens[index + 1 :])
            break
        if token == "--set-cursor":
            options["cursor"] = True
            index += 1
        elif token in ("--add", "-a", "--command", "--function", "--regex", "--position"):
            key = "add" if token == "-a" else token[2:]
            options[key] = tokens[index + 1]
            index += 2
        elif token.startswith("--position="):
            options["position"] = token.partition("=")[2]
            index += 1
        else:
            remaining.append(token)
            index += 1

    name = str(options.get("add") or remaining.pop(0))
    replacement = " ".join(remaining)
    if VALUE_SUBSTITUTIONS is not None:
        for old, new in VALUE_SUBSTITUTIONS.items():
            if type(old) == re.Pattern:
                replacement = re.sub(old, new, replacement)
            else:
                replacement = replacement.replace(old, new)
    return name, replacement, options


def generate(
    source: Path,
    mapping: "FishMapping",
    *,
    title: str,
    function_name: str,
    declaration_factory: DeclarationFactory,
    should_skip: Callable[[str, str, dict[str, str | bool]], bool] = (
        lambda _name, _replacement, _options: False
    ),
    deduplicated_names: frozenset[str] = frozenset(),
    call_register: bool = False,
) -> str:
    """Render one importable Xonsh module from a Fish source file."""
    # print("gen mapping", mapping)
    declarations = []
    functions = []
    seen = set()
    for line in source.read_text().splitlines():
        if "# fish-only" in line:
            continue
        if re.match(r"^\s*abbr(?:\s|$)", line):
            parsed = parse_abbreviation(line, VALUE_SUBSTITUTIONS=mapping.VALUE_SUBSTITUTIONS)
            name, replacement, options = parsed
            identity = (name, replacement, tuple(sorted(options.items())))
            duplicate = name in deduplicated_names and identity in seen
            if not should_skip(name, replacement, options) and not duplicate:
                declarations.append(declaration_factory(*parsed))
            seen.add(identity)
        function_match = re.match(r"^\s*function\s+([^\s]+)", line)
        if function_match:
            functions.append(function_match.group(1))

    declaration_text = "\n".join(declarations)

    register_text = "" if not call_register else f"\n\n{function_name}()"

    return f'''\
"""{title}"""

from __future__ import annotations

import re
import os
import platform

from xonsh.built_ins import XSH
from wes_abbreviations import abbr
from wes_fish_migration import (
    wrap_fish_functions,
    abbr_from_fish_function,
    platform_abbreviation,
    unsupported_abbreviation,
)


def {function_name}():
    fish_funcs = (
{"".join(f"        {name!r},\n" for name in functions)}\
    )
    wrap_fish_functions(XSH.aliases, fish_funcs)
{declaration_text}

{register_text}
'''

@dataclass(frozen=True)
class AbbreviationSelector:
    """Narrow a trigger rule by Fish command scope or original replacement."""

    trigger: str
    command: str | None = None
    replacement: str | None = None

    def matches(self, name, replacement, options):
        return (
            self.trigger == name
            and (self.command is None or self.command == options.get("command"))
            and (self.replacement is None or self.replacement == replacement)
        )


def matching_rule(rules, name, replacement, options, default=None):
    # Qualified rules take precedence over a plain trigger rule.
    for selector, value in rules.items():
        if isinstance(selector, AbbreviationSelector) and selector.matches(name, replacement, options):
            return value
    return rules.get(name, default)


_SKIPPED_ABBREVIATIONS = {
    # Linux alternatives folded into platform-aware declarations.
    AbbreviationSelector("pkill", replacement="pkill -9 -if"),
    AbbreviationSelector("pkillu", replacement="pkill -9 -U $USER -if"),
    AbbreviationSelector("lsusb", replacement="system_profiler SPUSBDataType"),
    # Templates have native registration helpers, not literal triggers.
    "$_abbr", "*$filetype_letter", "rg$filetype_letter",
    "tt_devtools_$name", "tail_all_devtools_$name", "tail_devtools_$name",
}

# Keep one copy of these identical declarations across Fish platform branches
# (or accidental duplicates). No occurrence numbers or source positions needed.
_DEDUPLICATED_ABBREVIATIONS = {"pgrep", "pgrepu", "hfmls_ggml_org"}


def should_skip(name, replacement, options):
    return any(
        selector.matches(name, replacement, options)
        if isinstance(selector, AbbreviationSelector) else selector == name
        for selector in _SKIPPED_ABBREVIATIONS
    )


_UNSUPPORTED_ABBREVIATIONS = {
    "pPATH": "uses Fish loop syntax to print the current shell PATH",
    "java19": "changes the current shell PATH",
}

_REPLACEMENTS = {
    "$fish_pid": "@(os.getpid())",
    '"$(_repo_root)"': "$(_repo_root)",
    "$sed_cmd": "$XONSH_SED_COMMAND",
    "$man_cmd": "$XONSH_MAN_COMMAND",
    "$_ls_http": "http paxy.lan:8016",
    "$_ls_prompt": "prompt='what is 11*2'",
    "$_ls_messages": 'messages:=[ {"role": "user", "content": "what is 11*2"} ]',
    "$_ollama_serve": "ollama serve 2>&1 | bat -pp -l log",
    "$sse_jq": "sed -E 's/^[^{]*//' | jq",
}

_NAME_OVERRIDES = {
    # The Fish source accidentally declares man7 three times; preserve intent.
    AbbreviationSelector("man7", replacement="$man_cmd 8"): "man8",
    AbbreviationSelector("man7", replacement="$man_cmd 9"): "man9",
}

_PLATFORM_REPLACEMENTS = {
    "pkill": ("pkill -9 -ilf", "pkill -9 -if"),
    "pkillu": ("pkill -9 -U $USER -ilf", "pkill -9 -U $USER -if"),
    "lsusb": ("system_profiler SPUSBDataType", "lsusb -tv"),
}

# Fish-native implementations whose Xonsh ports intentionally use structured
# helpers instead of reproducing the source command literally.
_MIGRATION_REPLACEMENTS = {
    "agr": "_abbr_list --any '%'",
    "agrs": "_abbr_list --prefix '%'",
    "py_profile_import_time": '$PYTHONPROFILEIMPORTTIME=1 python -c "from sentence_transformers import SentenceTransformer"',
    "vea": "source .venv*/bin/activate.xsh",
}


def declaration(name, replacement, options):
    name = matching_rule(_NAME_OVERRIDES, name, replacement, options, name)
    trigger = f"re.compile({options['regex']!r})" if "regex" in options else repr(name)
    unsupported = matching_rule(_UNSUPPORTED_ABBREVIATIONS, name, replacement, options)
    platform = matching_rule(_PLATFORM_REPLACEMENTS, name, replacement, options)
    if unsupported is not None:
        replacement_expression = (
            f"unsupported_abbreviation({name!r}, "
            f"{unsupported!r})"
        )
    elif platform is not None:
        replacement_expression = f"platform_abbreviation{platform!r}"
    elif "function" in options:
        replacement_expression = f"abbr_from_fish_function({options['function']!r})"
    else:
        replacement = matching_rule(_MIGRATION_REPLACEMENTS, name, replacement, options, replacement)
        for old, new in _REPLACEMENTS.items():
            replacement = replacement.replace(old, new)
        replacement_expression = repr(replacement)
    arguments = [trigger, replacement_expression]
    if options.get("position") == "anywhere" or options.get("command"):
        arguments.append('position="anywhere"')
    if options.get("command"):
        command = options["command"]
        command_expression = {
            "$man_cmd": "os.environ['XONSH_MAN_COMMAND']",
            "$sed_cmd": "os.environ['XONSH_SED_COMMAND']",
        }.get(command, repr(command))
        arguments.append(f"commands=({command_expression},)")
    if options.get("cursor") and replacement.count("%") == 1:
        arguments.append('cursor_marker="%"')
    return f"    abbr({', '.join(arguments)})"


@dataclass(frozen=True)
class FishMapping:
    fish_file: Path
    xonsh_module: Path
    VALUE_SUBSTITUTIONS: dict[str | re.Pattern, str]|None = None

def generate_wrapped(mapping: FishMapping, call_register: bool = False) -> str:
    function_name = "register_" + mapping.xonsh_module.with_suffix("").name
    return generate(
        mapping.fish_file,
        mapping = mapping,
        title=f""
        f"generated from Fish",
        function_name=function_name,
        declaration_factory=declaration,
        should_skip=should_skip,
        deduplicated_names=frozenset(_DEDUPLICATED_ABBREVIATIONS),
        call_register=call_register,
    )

