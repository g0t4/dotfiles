"""Diff helpers, including native Xonsh command-output process substitution."""

import subprocess
import sys

from prompt_toolkit.filters import EmacsInsertMode, ViInsertMode
from xonsh.built_ins import XSH
from xonsh.events import events

from wes_abbreviations import abbr
from wes_diff import (
    ProcessSubstitutionFiles,
    copied_patch_sides,
    diff_expansion,
    psub,
    restore_quoted_newline_escapes,
    sanitize_icdiff_label,
)


aliases = XSH.aliases

_ICDIFF_COLOR_MAP = (
    "add:green_bold,change:white_bold,description:blue,meta:magenta,"
    "separator:blue,subtract:red_bold"
)


def _icdiff(args, stdin=None, stdout=None, stderr=None, **_):
    executable = XSH.commands_cache.locate_binary("icdiff")
    if executable is None:
        print("icdiff: executable not found in Xonsh $PATH", file=stderr or sys.stderr)
        return 127
    return subprocess.run(
        [executable, f"--color-map={_ICDIFF_COLOR_MAP}", *args],
        stdin=stdin,
        stdout=stdout,
        stderr=stderr,
    ).returncode


aliases["icdiff"] = _icdiff
aliases["ic"] = ["icdiff"]
aliases["icr"] = ["icdiff", "--recursive"]
aliases["icg"] = ["git-icdiff"]

abbr("ic", "icdiff")
abbr("icr", "icdiff --recursive")
abbr("icg", "git-icdiff")
abbr("pba", "pbpaste > a")
abbr("pbb", "pbpaste > b")
abbr("icab", "icdiff a b")


def _xonsh_history_inputs():
    return XSH.history.inps or ()


def _diff_history_expansion(suffix=""):
    def expand(_context, _match):
        return diff_expansion(_xonsh_history_inputs(), suffix=suffix)

    return expand


abbr(
    "diff_last_two_commands",
    _diff_history_expansion(),
)
abbr(
    "diff_last_two_commands_sorted",
    _diff_history_expansion(" | sort -h"),
)
abbr(
    "diff_last_two_commands_stderr_too",
    _diff_history_expansion(" 2>&1"),
)


def _write_xonsh_command_output(command, path):
    # Evaluate inside this Xonsh process so current aliases, environment, and
    # working directory behave like Fish's `eval`, rather than a child shell.
    # A failed command still has useful output to compare. Suppress Xonsh's
    # subprocess exceptions only for this capture; preserve the user's global
    # failure settings everywhere else.
    with XSH.env.swap(
        XONSH_SUBPROC_CMD_RAISE_ERROR=False,
        XONSH_SUBPROC_RAISE_ERROR=False,
    ):
        command = restore_quoted_newline_escapes(command)
        output = XSH.execer.eval(
            f"$({command})",
            glbs=globals(),
            locs=locals(),
        )
    path.write_text((output or "").removesuffix("\n"))


def _diff_two_commands(args, stdout=None, stderr=None, **_):
    if len(args) < 2:
        print(
            "usage: diff_two_commands <command-a> <command-b> [icdiff options]",
            file=stderr or sys.stderr,
        )
        return 2
    command_a, command_b, *icdiff_args = args
    with psub((command_a, command_b), _write_xonsh_command_output) as paths:
        return _icdiff(
            [
                *icdiff_args,
                "-L",
                sanitize_icdiff_label(command_a),
                str(paths[0]),
                "-L",
                sanitize_icdiff_label(command_b),
                str(paths[1]),
            ],
            stdout=stdout,
            stderr=stderr,
        )


aliases["diff_two_commands"] = _diff_two_commands


def _diff_copied_patch(_args, stdout=None, stderr=None, **_):
    pasted = subprocess.run(["pbpaste"], capture_output=True, text=True)
    if pasted.returncode:
        print(pasted.stderr, end="", file=stderr or sys.stderr)
        return pasted.returncode
    sides = dict(zip(("after", "before"), copied_patch_sides(pasted.stdout)))

    def write_side(name, path):
        path.write_text(sides[name])

    with psub(("after", "before"), write_side) as paths:
        return _icdiff(
            [str(paths[0]), str(paths[1])], stdout=stdout, stderr=stderr
        )


aliases["diff_copied_patch__from_apply_patch"] = _diff_copied_patch


_process_substitutions = ProcessSubstitutionFiles()


def _psub_alias(args, stdin=None, stdout=None, stderr=None, **_):
    if args:
        print("usage: producer | psub", file=stderr or sys.stderr)
        return 2
    if stdin is None:
        print("psub: expected pipeline input", file=stderr or sys.stderr)
        return 2
    path = _process_substitutions.from_stream(stdin)
    print(path, file=stdout or sys.stdout)
    return 0


aliases["psub"] = _psub_alias


@events.on_postcommand
def _cleanup_process_substitutions(**_):
    _process_substitutions.cleanup()


def _convert_to_diff_two_commands(event):
    buffer = event.current_buffer
    command = buffer.text
    if not command.strip():
        previous = _xonsh_history_inputs()
        command = previous[-1] if previous else ""
    if not command:
        return
    quoted = __import__("shlex").quote(command)
    replacement = f"diff_two_commands {quoted} {__import__('shlex').quote(command + ' ')}"
    buffer.text = replacement
    # Put the cursor just before the closing quote of the editable second copy.
    buffer.cursor_position = max(0, len(replacement) - 1)


@events.on_ptk_create
def _diff_bindings(bindings, **_):
    bindings.add("f6", filter=ViInsertMode() | EmacsInsertMode())(
        _convert_to_diff_two_commands
    )
