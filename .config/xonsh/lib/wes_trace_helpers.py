"""Trace shortcuts: Fish owns the tools; Xonsh owns command-line expansion."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

from wes_abbreviations import abbr
from wes_fish_executable import find_fish
from wes_misc_functions import fish_command_alias


FISH_FUNCTIONS = (
    "ask_rewrite_diff_reviewer", "strip_trailing_newline", "browse_traces",
    "view_trace", "view_trace_tui", "trace_dump", "pii_scanner", "rag_indexer",
    "rag_validate_index", "notes_about_trace", "love_fim", "love_rewrites",
    "love_agents", "love_shell",
)

SHORTCUTS = {
    "bt": "browse_traces", "bta": "browse_traces agents",
    "btr": "browse_traces rewrite", "btf": "browse_traces fim",
    "btsh": "browse_traces fish", "btx": "browse_traces xonsh",
    "vt": "view_trace", "vtt": "view_trace_tui", "td": "trace_dump",
    "pii": "pii_scanner", "ri": "rag_indexer", "rvi": "rag_validate_index",
    "rag_rebuilder": "time rag_indexer --rebuild --info",
    "nreadme": "nvim README.md -c ':tabonly'",
    "nNOTES": "nvim NOTES.yml -c ':tabonly'",
}


def quote(value):
    """Xonsh/Fish single-quoted literal (POSIX quote concatenation is invalid here)."""
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def trace_files(*, recursive=False):
    # Deterministic selection, including names containing spaces. Avoid walking
    # a repository's Git internals when looking for a nested capture.
    pattern = "**/*-trace.json" if recursive else "*-trace.json"
    return sorted(
        path for path in Path('.').glob(pattern)
        if path.is_file() and '.git' not in path.parts
    )


def expand_trace_file(context, match):
    index = int(match.group(1) or 1)
    files = trace_files()
    selected = files[index - 1] if 1 <= index <= len(files) else None
    command = "AskViewTrace"
    if match.group(2):
        command += " --all"
    if selected is not None:
        # AskViewTrace forwards its raw arguments to `terminal view_trace`.
        # Quote once for that shell, then again below for `nvim -c`.
        command += " " + quote("./" + str(selected))
    # Always close the quote. The abbreviation engine preserves text following
    # this token; no Fish commandline call or dangling quote is needed.
    return "nvim -c " + quote(command)


def expand_trace_message(context, match):
    index = int(match.group(2))
    # Apply the upper bound independently to each input trace, unlike asking
    # Fish to compare an integer with jq's potentially multi-file output.
    query = f".request_body.messages | .[([{index}, length - 1] | min)]"
    if match.group(1) == "tc":
        query += ".tool_calls[].function.arguments"
        return "jq -r " + quote(query) + " ./*-trace.json | jq -r '.command_line // .code'"
    return "jq " + quote(query) + " ./*-trace.json"


def expand_message_field(context, match):
    files = trace_files(recursive=True)
    if not files:
        raise ValueError("No *-trace.json file found below the current directory")
    suffix, index = match.groups()
    field, tail = {
        "": ("", ""),
        "r": (".reasoning_content", " -r"),
        "c": (".content", " -r"),
        "f": (".tool_calls[0].function", ""),
        "args": (".tool_calls[0].function.arguments", " -r | jq '.'"),
        "patch": (".tool_calls[0].function.arguments", " -r | jq '.patch' -r | bat -l patch"),
    }[suffix or ""]
    query = f".request_body.messages[{int(index)}]{field}"
    return "cat " + quote("./" + str(files[0])) + " | jq " + quote(query) + tail


def register_trace_helpers(aliases, dotfiles):
    def trace_fish_alias(name):
        def invoke(args, stdin=None, stdout=None, stderr=None, **_):
            # No interactive startup: viewers still inherit the terminal, but
            # pipes and MCP protocol output receive no cursor-control escapes.
            source_root = Path(dotfiles) / "fish/load_last_interactive_only"
            return subprocess.run(
                [find_fish(), "-c",
                 'source $argv[1]; source $argv[2]; $argv[3] $argv[4..]',
                 "--", str(source_root / "always/my_ai.fish"),
                 str(source_root / "rag_captures.fish"), name, *args],
                stdin=stdin, stdout=stdout, stderr=stderr,
            ).returncode
        return invoke

    for name in (*FISH_FUNCTIONS, "mcp_server_semantic_grep"):
        # These require diff_two_commands / _repo_root from interactive Fish.
        aliases[name] = (fish_command_alias(name)
                         if name in {"ask_rewrite_diff_reviewer", "rag_validate_index"}
                         else trace_fish_alias(name))
    for trigger, replacement in SHORTCUTS.items():
        abbr(trigger, replacement)
    for trigger in ("nat", "notes_about_trace"):
        abbr(trigger, "notes_about_trace '%'", cursor_marker="%")
    abbr(re.compile(r"t(\d*)(a?)"), expand_trace_file)
    abbr(re.compile(r"(tm|tc)(\d+)"), expand_trace_message)
    abbr(re.compile(r"msg(r|f|c|args|patch)?(\d+)"), expand_message_field, position="anywhere")
    timing_query = ".request_body.messages[].timings | select(.) | [.cache_n, .prompt_n, .predicted_n] | @tsv"
    totals = '{a+=$1; b+=$2; c+=$3} END {print a "\\t" b "\\t" c}'
    abbr("trace_timings", "jq -r " + quote(timing_query)
         + " ./*-trace.json | awk " + quote(totals))
