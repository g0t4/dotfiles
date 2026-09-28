"""Compatibility bridge to functions still owned by interactive Fish config."""

from __future__ import annotations

import os
import re
import subprocess

from find_executables import find_fish


class FishFunctionError(RuntimeError):
    pass


class UnsupportedFishFunctionError(RuntimeError):
    pass


def fish_function_command(
    name: str,
    *args: str,
    stdin=None,
    stdout=None,
    stderr=None,
) -> int:
    """Run an interactive Fish function while preserving command I/O."""
    env = os.environ.copy()
    # FYI ONLY_CALL_FISH_WRAPPED_FUNC should be used in the fish config to stop any extra ANSI escape codes from being displayed
    env["ONLY_CALL_FISH_WRAPPED_FUNC"] = "true"
    completed = subprocess.run(
        [find_fish(), "-ic", "$argv[1] $argv[2..]", "--", name, *map(str, args)],
        stdin=stdin,
        stdout=stdout,
        stderr=stderr,
        env=env
    )
    return completed.returncode


def fish_function(
    name: str,
    *args: str,
    input_text: str | None = None,
    timeout: float = 5.0,
) -> str:
    """Call a function through the user's authoritative interactive Fish config.

    Values are passed through Fish's argv rather than interpolated into source.
    Interactive startup emits terminal setup sequences on this machine, so only
    those sequences are removed from captured output.
    """
    env = os.environ.copy()
    env["ONLY_CALL_FISH_WRAPPED_FUNC"] = "true"
    env.pop("TERM_PROGRAM", None)
    completed = subprocess.run(
        [find_fish(), "-ic", "$argv[1] $argv[2..]", "--", name, *map(str, args)],
        capture_output=True,
        text=True,
        input=input_text,
        timeout=timeout,
        env=env,
    )
    stdout = completed.stdout.rstrip("\n")
    stderr = completed.stderr.strip()
    if completed.returncode:
        detail = f": {stderr}" if stderr else ""
        raise FishFunctionError(
            f"fish function {name!r} exited {completed.returncode}{detail}"
        )
    return stdout
