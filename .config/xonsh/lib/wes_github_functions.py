"""GitHub repository setup and link helpers for interactive Xonsh."""

from __future__ import annotations

import subprocess
from typing import Callable, Sequence


DEFAULT_GITIGNORE_TEMPLATES = (
    "macos",
    "linux",
    "windows",
    "archives",
    "images",
    "video",
    "vim",
)


def run_gitignore_commit(
    templates: Sequence[str] = DEFAULT_GITIGNORE_TEMPLATES,
    *,
    run: Callable = subprocess.run,
) -> int:
    """Use the existing Zsh implementation until that domain is migrated."""
    command = "commit_gitignores_for " + " ".join(templates)
    return run(["zsh", "-ic", command]).returncode
