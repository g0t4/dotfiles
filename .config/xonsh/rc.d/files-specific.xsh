"""Filesystem abbreviations and Fish-backed file helpers."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from wes_files_abbreviations import register_files_abbreviations
from wes_fish_bridge import FishFunctionError, fish_function
from wes_fish_z import FishZ, FishZError


# Entering a directory in command position changes to it without an explicit cd.
$AUTO_CD = True
$EDITOR = "nvim"

register_files_abbreviations(XONSH_ABBREVIATIONS)


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
    return _files_original_cd(adjusted, stdin=stdin)


aliases["cd"] = _files_cd


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
    prefix = subprocess.run(
        ["brew", "--prefix", args[0]], capture_output=True, text=True
    )
    if prefix.returncode == 0:
        path = prefix.stdout.strip()
    else:
        caskroom = subprocess.run(
            ["brew", "--caskroom"], capture_output=True, text=True
        ).stdout.strip()
        path = os.path.join(caskroom, args[0])
    return _files_cd_to_path(path, stdout=stdout, stderr=stderr)


aliases["cd_dir_of_brew_pkg"] = _cd_dir_of_brew_pkg


def _cd_last_dir(args, stdout=None, stderr=None, **_):
    if args:
        print("cd_last_dir__in_current_dir takes no arguments", file=stderr or sys.stderr)
        return 2
    directories = subprocess.run(
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
    repo = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
    )
    repo_path = repo.stdout.strip() if repo.returncode == 0 else os.getcwd()
    command = [application] + ([] if application == "nvim" else [repo_path])
    return subprocess.run(command).returncode


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

# TODO SKIPPED_MIGRATION: Fish's ls/cat/tree overrides. Delegating them through
# `fish -ic` loses native TTY/streaming semantics, so stock Xonsh commands remain.
# TODO SKIPPED_MIGRATION: `complete -c batman -w man`; no Xonsh completion wrapper yet.
# TODO SKIPPED_MIGRATION: Alt-Shift-D/F/U/B/G FZF picker bindings. Their Fish
# functions edit `commandline`; they require native Prompt Toolkit buffer ports.
