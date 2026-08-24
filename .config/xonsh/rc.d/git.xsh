"""Git abbreviations and Fish-backed compatibility functions."""

import sys
import subprocess

from wes_fish_bridge import FishFunctionError, fish_function
from wes_git_abbreviations import register_git_abbreviations
from wes_git_functions import format_line_numbers


register_git_abbreviations(XONSH_ABBREVIATIONS)


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
