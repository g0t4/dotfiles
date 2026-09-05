"""Git abbreviations and Fish-backed compatibility functions."""

import sys
import subprocess
from pathlib import Path

from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import RichCompletion, contextual_command_completer

from wes_fish_bridge import FishFunctionError, fish_function
from wes_git_abbreviations import register_git_abbreviations
from wes_git_functions import (
    format_line_numbers,
    git_add_candidates,
    matching_git_add_candidates,
)


register_git_abbreviations()


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


def _fish_compatibility_alias(function_name):
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


# Fish remains authoritative during the migration. These are native Xonsh
# aliases only in the sense that Xonsh dispatches them; behavior comes from the
# existing interactive Fish definitions.
for _fish_git_function in (
    "mark",
    "git_unpushed_commits",
    "git_unpulled_commits",
    "git_current_branch",
    "git_current_branch_upstream",
    "hunkdiff",
    "prd",
    "_repo_root",
    "_repo_is_index_clean",
    "_repo_is_worktree_clean",
    "_get_license",
    "get_license_DWTFYW",
    "get_license_MIT0",
):
    aliases[_fish_git_function] = _fish_compatibility_alias(_fish_git_function)


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
