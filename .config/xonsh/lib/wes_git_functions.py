"""Native helpers required where interactive Fish cannot preserve semantics."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path


YELLOW = "\x1b[33m"
NORMAL = "\x1b[0m"


def format_line_numbers(text: str) -> str:
    """Mirror the numbered, yellow awk output used by Fish's line_numbers."""
    return "".join(
        f"{YELLOW}{number:4d}{NORMAL} {line}\n"
        for number, line in enumerate(text.splitlines(), 1)
    )


def git_add_candidates(cwd: Path) -> list[str]:
    """Return unstaged and untracked paths relative to the current directory."""
    root_result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=cwd,
        capture_output=True,
        text=True,
    )
    if root_result.returncode:
        return []

    root = Path(root_result.stdout.rstrip("\n"))
    files_result = subprocess.run(
        [
            "git",
            "ls-files",
            "-z",
            "--others",
            "--modified",
            "--deleted",
            "--exclude-standard",
        ],
        cwd=root,
        capture_output=True,
    )
    if files_result.returncode:
        return []

    paths = files_result.stdout.decode(errors="surrogateescape").split("\0")
    return sorted(
        os.path.relpath(root / path, cwd)
        for path in paths
        if path
    )


def matching_git_add_candidates(candidates: list[str], query: str) -> list[str]:
    """Match the typed fragment anywhere in a repository-relative path."""
    folded_query = query.casefold()
    return [path for path in candidates if folded_query in path.casefold()]
