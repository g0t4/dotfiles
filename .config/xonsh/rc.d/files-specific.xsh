"""Filesystem abbreviations and Fish-backed file helpers."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.filters import EmacsInsertMode, ViInsertMode
from prompt_toolkit.input import ansi_escape_sequences
from prompt_toolkit.input.vt100_parser import _IS_PREFIX_OF_LONGER_MATCH_CACHE
from prompt_toolkit.keys import Keys
from xonsh.parsers.completion_context import CompletionContextParser

from wes_files_abbreviations import register_files_abbreviations
from wes_fish_bridge import FishFunctionError, fish_function
from wes_fish_z import FishZ, FishZError
from wes_interactive_cat import InteractiveCat
from wes_logging import ensure_logger_is_setup, get_logger
from wes_fzf_pickers import (
    FzfMru,
    apply_path_selection,
    apply_variable_selection,
    ordered_candidates,
    parse_git_ref_token,
    xonsh_env_candidates,
)


# Entering a directory in command position changes to it without an explicit cd.
$AUTO_CD = True
$EDITOR = "nvim"

register_files_abbreviations()

${...}.setdefault("XONSH_KEYPRESS_DEBUG", False)
ensure_logger_is_setup()
log = get_logger("fzf_pickers")
log = get_logger("files")



def _files_picker_key_event(event):
    return [
        {"key": str(key_press.key), "data": repr(key_press.data)}
        for key_press in event.key_sequence
    ]


def _files_install_keypress_tee(prompter):
    if prompter is None:
        return
    key_processor = prompter.app.key_processor
    if getattr(key_processor, "_wes_keypress_tee_installed", False):
        return
    original_feed_multiple = key_processor.feed_multiple

    def feed_multiple(key_presses, first=False):
        keys = list(key_presses)
        if bool(${...}.get("XONSH_KEYPRESS_DEBUG", False)):
            log.info(
                "key_feed first=%s keys=%r",
                first,
                [
                    {"key": str(key_press.key), "data": repr(key_press.data)}
                    for key_press in keys
                ],
            )
        return original_feed_multiple(keys, first=first)

    key_processor.feed_multiple = feed_multiple
    key_processor._wes_keypress_tee_installed = True


def _files_run(*args, **kwargs):
    """Run with the live Xonsh environment, including its current PATH."""
    kwargs.setdefault("env", ${...}.detype())
    return subprocess.run(*args, **kwargs)


def _files_fish_alias(function_name):
    def invoke(args, stdin=None, stdout=None, stderr=None, **_):
        input_text = stdin.read() if stdin is not None else None
        try:
            output = fish_function(function_name, *args, input_text=input_text)
        except FishFunctionError as error:
            print(error, file=stderr or sys.stderr)
            return 1
        if output:
            print(output, file=stdout or sys.stdout)
        return 0

    return invoke


for _files_fish_function in (
    "_update_dotfile_et_al",
    "_update_os_lazy",
    "_update_completion",
    "touchp",
    "mkpath",
    "remkdir",
    "dir_of_man_page",
    "batman",
    "gpristine_nested_repos",
    "treed",
    "treeh",
    "treeu",
    "nvselect",
    "prepend_to_file",
    "shebangify",
):
    aliases[_files_fish_function] = _files_fish_alias(_files_fish_function)


_files_original_cd = aliases["cd"]


def _files_cd(args, stdin=None, **_):
    adjusted = list(args)
    if len(adjusted) == 1 and os.path.isfile(os.path.expanduser(adjusted[0])):
        adjusted[0] = os.path.dirname(os.path.expanduser(adjusted[0])) or "."
    olddir = os.getcwd()
    path_before = [str(entry) for entry in $PATH]
    log.info(
        "cd_start args=%r adjusted=%r cwd=%r path=%r",
        args,
        adjusted,
        olddir,
        path_before,
    )
    result = _files_original_cd(adjusted, stdin=stdin)
    path_after = [str(entry) for entry in $PATH]
    log.info(
        "cd_complete args=%r result=%r olddir=%r newdir=%r "
        "path_added=%r path_removed=%r path=%r",
        adjusted,
        result,
        olddir,
        os.getcwd(),
        [entry for entry in path_after if entry not in path_before],
        [entry for entry in path_before if entry not in path_after],
        path_after,
    )
    return result


aliases["cd"] = _files_cd


# This intentionally does not affect scripts or `xonsh -c`: the richer behavior
# is a REPL affordance, while non-interactive callers retain the system cat.
if bool(${...}.get("XONSH_INTERACTIVE", False)):
    aliases["cat"] = InteractiveCat(env=${...})


def _files_cd_to_path(path, stdout=None, stderr=None):
    output_stream = stdout or sys.stdout
    error_stream = stderr or sys.stderr
    expanded = Path(path).expanduser()
    if not expanded.exists():
        print(f"{expanded} not found", file=error_stream)
        return 1
    if expanded.is_symlink():
        resolved = expanded.resolve()
        print(f"symlink:\n   {expanded} =>\n   {resolved}", file=output_stream)
        expanded = resolved
    destination = expanded if expanded.is_dir() else expanded.parent
    cd_stdout, cd_stderr, return_code = _files_original_cd([str(destination)])
    if cd_stdout:
        print(cd_stdout, end="", file=output_stream)
    if cd_stderr:
        print(cd_stderr, end="", file=error_stream)
    return return_code


def _cd_dir_of_path(args, stdout=None, stderr=None, **_):
    if len(args) != 1:
        print("usage: cd_dir_of_path <path>", file=stderr or sys.stderr)
        return 2
    return _files_cd_to_path(args[0], stdout=stdout, stderr=stderr)


aliases["cd_dir_of_path"] = _cd_dir_of_path


def _cd_dir_of_command(args, stdout=None, stderr=None, **_):
    if len(args) != 1:
        print("usage: cd_dir_of_command <command>", file=stderr or sys.stderr)
        return 2
    command_path = shutil.which(args[0])
    if command_path is None:
        print(f"command not found: {args[0]}", file=stderr or sys.stderr)
        return 1
    return _files_cd_to_path(command_path, stdout=stdout, stderr=stderr)


aliases["cd_dir_of_command"] = _cd_dir_of_command


def _cd_dir_of_man_page(args, stdout=None, stderr=None, **_):
    if len(args) != 1:
        print("usage: cd_dir_of_man_page <page>", file=stderr or sys.stderr)
        return 2
    try:
        man_path = fish_function("dir_of_man_page", args[0])
    except FishFunctionError as error:
        print(error, file=stderr or sys.stderr)
        return 1
    return _files_cd_to_path(man_path, stdout=stdout, stderr=stderr)


aliases["cd_dir_of_man_page"] = _cd_dir_of_man_page


def _cd_dir_of_brew_pkg(args, stdout=None, stderr=None, **_):
    if len(args) != 1:
        print("usage: cd_dir_of_brew_pkg <package>", file=stderr or sys.stderr)
        return 2
    prefix = _files_run(
        ["brew", "--prefix", args[0]], capture_output=True, text=True
    )
    if prefix.returncode == 0:
        path = prefix.stdout.strip()
    else:
        caskroom = _files_run(
            ["brew", "--caskroom"], capture_output=True, text=True
        ).stdout.strip()
        path = os.path.join(caskroom, args[0])
    return _files_cd_to_path(path, stdout=stdout, stderr=stderr)


aliases["cd_dir_of_brew_pkg"] = _cd_dir_of_brew_pkg


def _cd_last_dir(args, stdout=None, stderr=None, **_):
    if args:
        print("cd_last_dir__in_current_dir takes no arguments", file=stderr or sys.stderr)
        return 2
    directories = _files_run(
        ["fd", "--type", "dir", "--exact-depth", "1"],
        capture_output=True,
        text=True,
    ).stdout.splitlines()
    if not directories:
        print("no subdirectories found", file=stderr or sys.stderr)
        return 1
    return _files_cd_to_path(directories[-1], stdout=stdout, stderr=stderr)


aliases["cd_last_dir__in_current_dir"] = _cd_last_dir


def _take(args, stdout=None, stderr=None, **_):
    if not args:
        print("usage: take newdir [file ...]", file=stderr or sys.stderr)
        return 2
    destination = Path(args[0]).expanduser()
    destination.mkdir(parents=True, exist_ok=True)
    for source in args[1:]:
        shutil.move(source, destination)
    return _files_cd_to_path(destination, stdout=stdout, stderr=stderr)


aliases["take"] = _take


_files_z = FishZ()


def _z_and_open(application, args, stdout=None, stderr=None):
    try:
        destination = _files_z.resolve(args)
    except FishZError as error:
        print(f"z: {error}", file=stderr or sys.stderr)
        return 1
    return_code = _files_cd_to_path(destination, stdout=stdout, stderr=stderr)
    if return_code:
        return return_code
    repo = _files_run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
    )
    repo_path = repo.stdout.strip() if repo.returncode == 0 else os.getcwd()
    command = [application] + ([] if application == "nvim" else [repo_path])
    return _files_run(command).returncode


for _z_application, _z_alias_name in (
    ("code", "cz"),
    ("zed", "zz"),
    ("open", "oz"),
    ("nvim", "nz"),
):
    aliases[_z_alias_name] = (
        lambda args, stdout=None, stderr=None, _application=_z_application, **_: (
            _z_and_open(_application, args, stdout=stdout, stderr=stderr)
        )
    )


def _files_unsupported(function_name, reason):
    def invoke(args, stderr=None, **_):
        print(
            f"{function_name}: TODO SKIPPED_MIGRATION: {reason}",
            file=stderr or sys.stderr,
        )
        return 2

    return invoke


aliases["_reload_config"] = _files_unsupported(
    "_reload_config", "sourcing Fish cannot reload Xonsh"
)
aliases["supercd"] = _files_unsupported(
    "supercd", "its Fish implementation changes directory and edits an interactive fzf UI"
)


_files_fzf_mru = FzfMru()
_files_completion_parser = CompletionContextParser()

# Enhanced keyboard protocols encode Alt-Shift-letter as one CSI sequence
# instead of the legacy Escape + uppercase-letter pair Prompt Toolkit expects.
# Translate both common encodings back into that portable key pair.
for _files_picker_key in "DFUBGV":
    for _files_picker_codepoint in (
        ord(_files_picker_key),
        ord(_files_picker_key.lower()),
    ):
        ansi_escape_sequences.ANSI_SEQUENCES[
            f"\x1b[{_files_picker_codepoint};4u"
        ] = (Keys.Escape, _files_picker_key)
        ansi_escape_sequences.ANSI_SEQUENCES[
            f"\x1b[27;4;{_files_picker_codepoint}~"
        ] = (Keys.Escape, _files_picker_key)
_IS_PREFIX_OF_LONGER_MATCH_CACHE.clear()

_FILES_PICKER_COMMANDS = {
    "dirs": ["fd", "--type", "d", "."],
    "files": ["fd", "--type", "f", "--type", "symlink", "."],
    "unrestricted": [
        "fd",
        "--type",
        "f",
        "--type",
        "symlink",
        ".",
        "-u",
    ],
    "both": [
        "fd",
        "--type",
        "f",
        "--type",
        "d",
        "--type",
        "symlink",
        ".",
    ],
}


def _files_current_token(buffer):
    completion = _files_completion_parser.parse(
        buffer.text, buffer.cursor_position, ctx={}
    )
    if completion is None or completion.command is None:
        return "", buffer.cursor_position, buffer.cursor_position
    command = completion.command
    token = command.prefix + command.suffix
    start = buffer.cursor_position - len(command.prefix)
    return token, start, buffer.cursor_position + len(command.suffix)


def _files_picker_candidates(picker, git_ref, cwd):
    if git_ref:
        command = ["git", "ls-tree", "-r", "--name-only", git_ref]
    else:
        command = _FILES_PICKER_COMMANDS[picker]
    completed = _files_run(command, capture_output=True, text=True, cwd=cwd)
    if completed.returncode:
        return None, completed.stderr
    fresh = completed.stdout.splitlines()
    mru = _files_fzf_mru.read(picker, cwd)
    return ordered_candidates(mru, fresh), None


def _files_run_path_picker(picker, token, cwd):
    git_ref, query = parse_git_ref_token(token)
    candidates, error = _files_picker_candidates(picker, git_ref, cwd)
    if candidates is None:
        print(error, end="", file=sys.stderr)
        return None, git_ref
    fzf = _files_run(
        [
            "fzf",
            "--height",
            "50%",
            "--border",
            "--header",
            "MRU ↑  |  Fresh ↓",
            "--query",
            query,
        ],
        input="".join(f"{candidate}\n" for candidate in candidates),
        stdout=subprocess.PIPE,
        text=True,
        cwd=cwd,
    )
    selected = fzf.stdout.rstrip("\n") if fzf.returncode == 0 else None
    if selected:
        _files_fzf_mru.record(picker, selected, cwd)
    return selected, git_ref


def _files_run_commit_picker(cwd):
    log_format = "%C(white)%h%Creset %Cblue%cr%Creset%C(auto)%d%Creset %s"
    log = _files_run(
        ["git", "log", "--reverse", f"--format={log_format}"],
        capture_output=True,
        text=True,
        cwd=cwd,
    )
    if log.returncode:
        print(log.stderr, end="", file=sys.stderr)
        return None
    fzf = _files_run(
        ["fzf", "--height", "50%", "--border", "--ansi", "--accept-nth=1"],
        input=log.stdout,
        stdout=subprocess.PIPE,
        text=True,
        cwd=cwd,
    )
    return fzf.stdout.strip() if fzf.returncode == 0 else None


def _files_run_variable_picker(query, cwd):
    candidates = xonsh_env_candidates(${...}.keys())
    fzf = _files_run(
        [
            "fzf",
            "--height",
            "50%",
            "--border",
            "--header",
            "Xonsh environment variables",
            "--query",
            query.lstrip("$"),
        ],
        input="".join(f"{candidate}\n" for candidate in candidates),
        stdout=subprocess.PIPE,
        text=True,
        cwd=cwd,
    )
    return fzf.stdout.rstrip("\n") if fzf.returncode == 0 else None


def _files_path_picker_handler(picker):
    async def pick(event):
        buffer = event.current_buffer
        token, token_start, token_end = _files_current_token(buffer)
        cwd = Path.cwd()
        log.info(
            "picker_start picker=%s keys=%r cwd=%r buffer=%r token=%r",
            picker,
            _files_picker_key_event(event),
            str(cwd),
            buffer.text,
            token,
        )
        selected, git_ref = await run_in_terminal(
            lambda: _files_run_path_picker(picker, token, cwd)
        )
        log.info(
            "picker_result picker=%s selected=%r git_ref=%r", picker, selected, git_ref
        )
        if selected:
            buffer.text, buffer.cursor_position = apply_path_selection(
                buffer.text,
                token_start,
                token_end,
                selected,
                git_ref=git_ref,
            )
        event.app.invalidate()

    return pick


async def _files_commit_picker_handler(event):
    log.info(
        "picker_start picker=commits keys=%r cwd=%r buffer=%r",
        _files_picker_key_event(event),
        str(Path.cwd()),
        event.current_buffer.text,
    )
    selected = await run_in_terminal(lambda: _files_run_commit_picker(Path.cwd()))
    log.info("picker_result picker=commits selected=%r", selected)
    if selected:
        event.current_buffer.insert_text(selected)
    event.app.invalidate()


async def _files_variable_picker_handler(event):
    buffer = event.current_buffer
    token, token_start, token_end = _files_current_token(buffer)
    cwd = Path.cwd()
    log.info(
        "picker_start picker=variables keys=%r cwd=%r buffer=%r token=%r",
        _files_picker_key_event(event),
        str(cwd),
        buffer.text,
        token,
    )
    selected = await run_in_terminal(
        lambda: _files_run_variable_picker(token, cwd)
    )
    log.info("picker_result picker=variables selected=%r", selected)
    if selected:
        buffer.text, buffer.cursor_position = apply_variable_selection(
            buffer.text,
            token_start,
            token_end,
            selected,
        )
    event.app.invalidate()


@events.on_ptk_create
def _files_fzf_picker_bindings(bindings, prompter=None, **_):
    # Alt bindings rely on the iTerm2 Esc+ input contract documented in
    # keybindings.xsh. Do not use raw 8-bit Meta bytes for these chords.
    _files_install_keypress_tee(prompter)
    insert_modes = ViInsertMode() | EmacsInsertMode()
    for key, picker in (
        ("D", "dirs"),
        ("F", "files"),
        ("U", "unrestricted"),
        ("B", "both"),
    ):
        handler = _files_path_picker_handler(picker)
        bindings.add("escape", key, filter=insert_modes)(handler)

    bindings.add("escape", "G", filter=insert_modes)(_files_commit_picker_handler)
    bindings.add("escape", "V", filter=insert_modes)(_files_variable_picker_handler)

# TODO SKIPPED_MIGRATION: Fish's ls/tree overrides. Delegating them through
# `fish -ic` loses native TTY/streaming semantics, so stock Xonsh commands remain.
# TODO SKIPPED_MIGRATION: `complete -c batman -w man`; no Xonsh completion wrapper yet.
