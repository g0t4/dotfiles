"""GitHub repository helpers migrated from interactive Fish config."""

import os
import shutil
import subprocess
import sys

from wes_github_functions import run_gitignore_commit
from wes_abbreviations import abbr
from wes_misc_functions import fish_command_alias


def _github_executable(name):
    """Resolve against Xonsh's live PATH, which may differ from os.environ."""
    live_path = os.pathsep.join(map(str, ${...}.get("PATH", ())))
    executable = shutil.which(name, path=live_path)
    if executable is None:
        raise FileNotFoundError(f"{name}: executable not found in Xonsh PATH")
    return executable


def _github_run(command, *, error, stdout=None, stderr=None):
    completed = subprocess.run(command, stdout=stdout, stderr=stderr)
    if completed.returncode:
        print(error, file=stderr or sys.stderr)
    return completed.returncode


def _github_create_clone_with_ignores(repository_name, *, stdout=None, stderr=None):
    wcl = aliases.get("wcl")
    if not callable(wcl) or wcl([repository_name], stdout=stdout, stderr=stderr):
        print("Failed to wcl...", file=stderr or sys.stderr)
        return 1

    z = aliases.get("z")
    if not callable(z) or z([repository_name], stdout=stdout, stderr=stderr):
        print("Failed to z...", file=stderr or sys.stderr)
        return 1

    return run_gitignore_commit()


def _gh_repo_create(args, *, private, stdout=None, stderr=None):
    if len(args) != 1:
        print("No repo name provided, aborting...", file=stderr or sys.stderr)
        return 2

    repository_name = args[0]
    if private and not repository_name.startswith("private-"):
        repository_name = f"private-{repository_name}"
    visibility = "--private" if private else "--public"
    try:
        gh = _github_executable("gh")
    except FileNotFoundError as error:
        print(error, file=stderr or sys.stderr)
        return 127
    if _github_run(
        [gh, "repo", "create", visibility, repository_name],
        error="Failed to create repo...",
        stdout=stdout,
        stderr=stderr,
    ):
        return 1

    result = _github_create_clone_with_ignores(
        repository_name, stdout=stdout, stderr=stderr
    )
    if not private and repository_name.startswith("course"):
        for _ in range(10):
            print(
                "Does this course require 'main' branch? If so set it manually",
                file=stderr or sys.stderr,
            )
    return result


def _gh_repo_create_private(args, stdout=None, stderr=None, **_):
    return _gh_repo_create(args, private=True, stdout=stdout, stderr=stderr)


def _gh_repo_create_public(args, stdout=None, stderr=None, **_):
    return _gh_repo_create(args, private=False, stdout=stdout, stderr=stderr)


aliases["gh_repo_create_private"] = _gh_repo_create_private
aliases["gh_repo_create_public"] = _gh_repo_create_public

# These functions only affect subprocess state, output, or the clipboard, so
# Fish can remain authoritative without losing changes in the live Xonsh REPL.
for _github_fish_function in (
    "copy_github_link",
    "copy_github_raw_link",
    "__gh_depoliticize",
):
    aliases[_github_fish_function] = fish_command_alias(_github_fish_function)

abbr("ghrc", "gh_repo_create_private")
abbr("ghrcp", "gh_repo_create_public")
