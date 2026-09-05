"""Python and uv abbreviations migrated from interactive Fish config."""

import subprocess
import sys
from pathlib import Path

from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import RichCompletion, contextual_command_completer
from xonsh.dirstack import cd as _xonsh_cd

from wes_misc_functions import register_misc_fish_functions
from wes_python_abbreviations import FISH_FUNCTIONS, register_python_abbreviations
from wes_python_functions import run_wcl, wcl_completion_candidates


$PYTEST_ADDOPTS = "-o verbosity_assertions=2"

register_python_abbreviations()
register_misc_fish_functions(aliases, FISH_FUNCTIONS)


_wcl_script = Path($WES_DOTFILES) / "zsh/compat_fish/pythons/wcl.py"
_wcl_python = Path($WES_DOTFILES) / ".venv/bin/python3"


def _wcl_alias(args, stdin=None, stdout=None, stderr=None, **_):
    return run_wcl(
        args,
        script=_wcl_script,
        python=_wcl_python,
        cd=_xonsh_cd,
        stdin=stdin,
        stdout=stdout,
        stderr=stderr,
    )


aliases["wcl"] = _wcl_alias


def _wcl_repository_names():
    completed = subprocess.run(
        ["gh", "repo", "list", "--json", "name", "--jq", ".[].name", "--limit", "1000"],
        capture_output=True,
        text=True,
        timeout=5,
    )
    if completed.returncode:
        return []
    return completed.stdout.splitlines()


@contextual_command_completer
def _wcl_completer(command):
    if command.command != "wcl" or command.arg_index < 1:
        return None
    try:
        repositories = [] if command.prefix.startswith("-") else _wcl_repository_names()
    except (OSError, subprocess.SubprocessError):
        repositories = []
    return {
        RichCompletion(
            value,
            prefix_len=len(command.prefix),
            append_space=True,
            provider="wcl",
        )
        for value in wcl_completion_candidates(command.prefix, repositories)
    }


add_one_completer("wcl", _wcl_completer, "start")
