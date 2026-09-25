"""Dotfiles-specific policies for generating Xonsh from Fish abbreviations."""

from __future__ import annotations

from pathlib import Path
import re
from dataclasses import dataclass

from fish_to_xonsh import generate

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


SKIPPED_ABBREVIATIONS = {
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
DEDUPLICATED_ABBREVIATIONS = {"pgrep", "pgrepu", "hfmls_ggml_org"}


def should_skip(name, replacement, options):
    return any(
        selector.matches(name, replacement, options)
        if isinstance(selector, AbbreviationSelector) else selector == name
        for selector in SKIPPED_ABBREVIATIONS
    )


UNSUPPORTED_ABBREVIATIONS = {
    "pPATH": "uses Fish loop syntax to print the current shell PATH",
    "java19": "changes the current shell PATH",
}

REPLACEMENTS = {
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

NAME_OVERRIDES = {
    # The Fish source accidentally declares man7 three times; preserve intent.
    AbbreviationSelector("man7", replacement="$man_cmd 8"): "man8",
    AbbreviationSelector("man7", replacement="$man_cmd 9"): "man9",
}

PLATFORM_REPLACEMENTS = {
    "pkill": ("pkill -9 -ilf", "pkill -9 -if"),
    "pkillu": ("pkill -9 -U $USER -ilf", "pkill -9 -U $USER -if"),
    "lsusb": ("system_profiler SPUSBDataType", "lsusb -tv"),
}

# Fish-native implementations whose Xonsh ports intentionally use structured
# helpers instead of reproducing the source command literally.
MIGRATION_REPLACEMENTS = {
    "agr": "_abbr_list --any '%'",
    "agrs": "_abbr_list --prefix '%'",
}


def declaration(line_number, name, replacement, options):
    name = matching_rule(NAME_OVERRIDES, name, replacement, options, name)
    trigger = f"re.compile({options['regex']!r})" if "regex" in options else repr(name)
    unsupported = matching_rule(UNSUPPORTED_ABBREVIATIONS, name, replacement, options)
    platform = matching_rule(PLATFORM_REPLACEMENTS, name, replacement, options)
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
        replacement = matching_rule(MIGRATION_REPLACEMENTS, name, replacement, options, replacement)
        for old, new in REPLACEMENTS.items():
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

def generate_wrapped(mapping: FishMapping, call_register: bool = False) -> str:
    function_name = "register_" + mapping.xonsh_module.with_suffix("").name
    return generate(
        mapping.fish_file,
        title=f""
        f"generated from Fish",
        function_name=function_name,
        declaration_factory=declaration,
        should_skip=should_skip,
        deduplicated_names=frozenset(DEDUPLICATED_ABBREVIATIONS),
        call_register=call_register,
    )
