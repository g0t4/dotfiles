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
    # These hooks are globally configured, but the derived artifacts below are
    # a convention for Wes and g0t4 repositories only.
    if not re.search(r"/(wes[^/]+|g0t4)/[^/]+$", str(repo)):
        return

    # A .ctags.d directory opts a repository into a conventional Makefile
    # `tags` target.
    if (
        (repo / ".ctags.d").is_dir()
        and (repo / "Makefile").is_file()
        and shutil.which("make")
    ):
        subprocess.run(["make", "tags"], cwd=repo, check=False)

    # A .rag.yaml file explicitly opts a repository into automatic indexing.
    # The indexer itself owns any finer-grained enable/disable policy.
    if (repo / ".rag.yaml").is_file() and shutil.which("rag_indexer"):
        subprocess.run(["rag_indexer", "--githook"], cwd=repo, check=False)


if __name__ == "__main__":
    main()
