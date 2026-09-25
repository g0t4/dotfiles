"""Git abbreviations and Fish-backed compatibility functions."""

from xonsh.built_ins import XSH

aliases = XSH.aliases

import sys
import subprocess
from pathlib import Path

from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import RichCompletion, contextual_command_completer

from wes_fish_bridge import FishFunctionError, fish_function
from wes_git import register_wes_git
from wes_git_functions import (
    format_line_numbers,
    git_add_candidates,
    matching_git_add_candidates,
)


register_wes_git()


@contextual_command_completer
def _git_add_dirty_completer(command):
    if (
        command.command != "git"
        or len(command.args) < 2
        or command.args[1].value != "add"
        or command.arg_index < 2
        or command.prefix.startswith("-")
    ):
        return None

    matches = matching_git_add_candidates(
        git_add_candidates(Path.cwd()), command.prefix
    )
    return {
        RichCompletion(
            path,
            prefix_len=len(command.prefix),
            append_space=True,
            provider="git-add-dirty",
        )
        for path in matches
    }


add_one_completer("git_add_dirty", _git_add_dirty_completer, "start")


# * override fish wrapped functions for git... provide xonsh native IMPL
# FYI define these functions after the wes_git fish_funcs are defined so the functions below take precedence
def _line_numbers_alias(args, stdin=None, stdout=None, stderr=None, **_):
    if args:
        print("line_numbers: arguments are not supported", file=stderr or sys.stderr)
        return 2
    numbered = format_line_numbers(stdin.read() if stdin is not None else "")
    return subprocess.run(
        ["less"],
        input=numbered,
        text=True,
        stdout=stdout,
        stderr=stderr,
    ).returncode
aliases["line_numbers"] = _line_numbers_alias
