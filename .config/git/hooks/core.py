#!/usr/bin/env python3
"""Shared work run after meaningful Git repository changes."""

import re
import shutil
import subprocess
from pathlib import Path


def main() -> None:
    completed = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if completed.returncode:
        return

    repo = Path(completed.stdout.strip())
    if not re.search(r"/(wes[^/]+|g0t4)/[^/]+$", str(repo)):
        return

    if (
        (repo / ".ctags.d").is_dir()
        and (repo / "Makefile").is_file()
        and shutil.which("make")
    ):
        subprocess.run(["make", "tags"], cwd=repo, check=False)

    if (repo / ".rag.yaml").is_file() and shutil.which("rag_indexer"):
        subprocess.run(["rag_indexer", "--githook"], cwd=repo, check=False)


if __name__ == "__main__":
    main()
