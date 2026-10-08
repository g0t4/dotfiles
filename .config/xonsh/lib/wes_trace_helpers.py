"""Trace shortcuts: Fish owns the tools; Xonsh owns command-line expansion."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

from wes_abbreviations import abbr
from find_executables import find_fish
from wes_fish_migration import fish_command_alias


FISH_FUNCTIONS = (
    "ask_rewrite_diff_reviewer",
    "browse_traces",
    "love_agents",
    "love_fim",
    "love_rewrites",
    "love_shell",
    "notes_about_trace",
    "pii_scanner",
    "rag_indexer",
    "rag_validate_index",
    "strip_trailing_newline",
    "trace_dump",
    "view_trace",
    "view_trace_tui",
)

abbr('bt', 'browse_traces')
abbr('bta', 'browse_traces agents')
abbr('btr', 'browse_traces rewrite')
abbr('btf', 'browse_traces fim')
abbr('btsh', 'browse_traces fish')
abbr('btx', 'browse_traces xonsh')
abbr('td', 'trace_dump')
abbr('pii', 'pii_scanner')
abbr('ri', 'rag_indexer')
abbr('rvi', 'rag_validate_index')
abbr('rag_rebuilder', 'time rag_indexer --rebuild --info')
abbr('nreadme', "nvim README.md -c ':tabonly'")
abbr('nNOTES', "nvim NOTES.yml -c ':tabonly'")


def single_quote(value):
    """Xonsh/Fish single-quoted literal (POSIX quote concatenation is invalid here)."""
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"

def double_quote(value):
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'


def trace_files(*, recursive=False):
    # Deterministic selection, including names containing spaces. Avoid walking
    # a repository's Git internals when looking for a nested capture.
    pattern = "**/*-trace.json" if recursive else "*-trace.json"
    return sorted(
        path for path in Path('.').glob(pattern)
        if path.is_file() and '.git' not in path.parts
    )


def expand_trace_file(context, match):
    trace_number = int(match.group(2) or 1)
    files = trace_files()
    selected = files[trace_number - 1] if 1 <= trace_number <= len(files) else None

    parts: list[str] = []
    if match.group(3):
        parts.append("--all")

    cmd_prefix = match.group(1)
    if cmd_prefix == "t":
        if selected is not None:
            # AskViewTrace forwards its raw arguments to `terminal view_trace`.
            # Quote once for that shell, then again below for `nvim -c`.
            parts.append(single_quote("./" + str(selected)))

        # example:
        #   nvim -c 'AskViewTrace \'./1790154300-trace.json\''

        # Always close the quote. The abbreviation engine preserves text following
        # this token; no Fish commandline call or dangling quote is needed.
        return "nvim -c " + double_quote(" ".join(["AskViewTrace"] + parts))

    # vt / vtt
    command = "view_trace" if cmd_prefix == "vt" else "view_trace_tui"
    if selected is not None:
        parts.append(str(selected))
    return f"{command} {' '.join(parts)}"


def expand_trace_message(context, match):
    message_num_base0 = int(match.group(2)) - 1
    # Apply the upper bound independently to each input trace, unlike asking
    # Fish to compare an integer with jq's potentially multi-file output.
    query = f".request_body.messages | .[([{message_num_base0}, length - 1] | min)]"
    if match.group(1) == "tc":
        query += ".tool_calls[].function.arguments"
        return "jq -r " + single_quote(query) + " ./*-trace.json | jq -r '.command_line // .code'"
    return "jq " + single_quote(query) + " ./*-trace.json"


def expand_message_field(context, match):
    files = trace_files(recursive=True)
    if not files:
        raise ValueError("No *-trace.json file found below the current directory")
    suffix, message_num_base1 = match.groups()
    message_num_base0 = int(message_num_base1) - 1
    field, tail = {
        "": ("", ""),
        "r": (".reasoning_content", " -r"),
        "c": (".content", " -r"),
        "f": (".tool_calls[0].function", ""),
        "args": (".tool_calls[0].function.arguments", " -r | jq '.'"),
        "patch": (".tool_calls[0].function.arguments", " -r | jq '.patch' -r | bat -l patch"),
    }[suffix or ""]
    query = f".request_body.messages[{message_num_base0}]{field}"
    return "cat " + single_quote("./" + str(files[0])) + " | jq " + single_quote(query) + tail


def register_trace_helpers(aliases, dotfiles):
    for name in (*FISH_FUNCTIONS, "mcp_server_semantic_grep"):
        aliases[name] = fish_command_alias(name)
    for trigger in ("nat", "notes_about_trace"):
        abbr(trigger, "notes_about_trace '%'", cursor_marker="%")
    abbr(re.compile(r"(t|vt|vtt)(\d*)(a?)"), expand_trace_file)
    abbr(re.compile(r"(tm|tc)(\d+)"), expand_trace_message)
    abbr(re.compile(r"msg(r|f|c|args|patch)?(\d+)"), expand_message_field, position="anywhere")
    timing_query = ".request_body.messages[].timings | select(.) | [.cache_n, .prompt_n, .predicted_n] | @tsv"
    totals = '{a+=$1; b+=$2; c+=$3} END {print a "\\t" b "\\t" c}'
    abbr("trace_timings", "jq -r " + single_quote(timing_query)
         + " ./*-trace.json | awk " + single_quote(totals))
