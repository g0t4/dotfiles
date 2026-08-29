"""Native Xonsh adapters for Python-domain shell functions."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import Callable


WCL_CD_PREFIX = "__wcl_cd "


def run_wcl(
    args: list[str],
    *,
    script: Path,
    python: Path,
    cd: Callable[[list[str]], tuple[str | None, str | None, int]],
    stdin=None,
    stdout=None,
    stderr=None,
) -> int:
    """Run wcl.py and apply its requested directory change to Xonsh."""
    output_stream = stdout or sys.stdout
    error_stream = stderr or sys.stderr
    completed = subprocess.run(
        [str(python), str(script), *map(str, args)],
        stdin=stdin,
        stdout=stdout,
        stderr=subprocess.PIPE,
        text=True,
    )

    destination = None
    for line in completed.stderr.splitlines(keepends=True):
        stripped = line.rstrip("\r\n")
        if stripped.startswith(WCL_CD_PREFIX):
            destination = Path(stripped.removeprefix(WCL_CD_PREFIX)).expanduser()
        else:
            print(line, end="", file=error_stream)

    if completed.returncode or destination is None:
        return completed.returncode
    if not destination.is_dir():
        print(f"wcl: requested directory does not exist: {destination}", file=error_stream)
        return 1

    cd_stdout, cd_stderr, return_code = cd([str(destination)])
    if cd_stdout:
        print(cd_stdout, end="", file=output_stream)
    if cd_stderr:
        print(cd_stderr, end="", file=error_stream)
    return return_code


def wcl_completion_candidates(prefix: str, repository_names: list[str]) -> list[str]:
    options = ["--cd", "--dry-run", "--path-only"]
    values = options if prefix.startswith("-") else repository_names
    return [value for value in values if value.startswith(prefix)]
