"""Compatibility bridge to functions still owned by interactive Fish config."""

from __future__ import annotations

import os
import re
import subprocess


_TERMINAL_ESCAPE = re.compile(
    r"(?:\x1b\][^\x07]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~])"
)


class FishFunctionError(RuntimeError):
    pass


def fish_function(name: str, *args: str, timeout: float = 5.0) -> str:
    """Call a function through the user's authoritative interactive Fish config.

    Values are passed through Fish's argv rather than interpolated into source.
    Interactive startup emits terminal setup sequences on this machine, so only
    those sequences are removed from captured output.
    """
    env = os.environ.copy()
    env["TERM"] = "dumb"
    env.pop("TERM_PROGRAM", None)
    completed = subprocess.run(
        ["fish", "-ic", "$argv[1] $argv[2..]", "--", name, *map(str, args)],
        capture_output=True,
        text=True,
        timeout=timeout,
        env=env,
    )
    stdout = _TERMINAL_ESCAPE.sub("", completed.stdout).rstrip("\n")
    stderr = _TERMINAL_ESCAPE.sub("", completed.stderr).strip()
    if completed.returncode:
        detail = f": {stderr}" if stderr else ""
        raise FishFunctionError(
            f"fish function {name!r} exited {completed.returncode}{detail}"
        )
    return stdout
