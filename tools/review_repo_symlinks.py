#!/usr/bin/env python3
"""Report checkout symlinks that lead outside the repository, including ignored links."""

import argparse
import os
import subprocess
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", default=".", nargs="?")
    parser.add_argument("--all", action="store_true", help="also inspect dependency and cache directories")
    args = parser.parse_args()
    root = Path(subprocess.check_output(
        ["git", "-C", args.repo, "rev-parse", "--show-toplevel"], text=True
    ).rstrip("\n")).resolve()
    generated = {".rag", ".venv", "node_modules", "__pycache__", ".pytest_cache", ".ruff_cache", "target"}
    found = False

    def raise_error(exc: OSError) -> None:
        raise exc

    for directory, dirs, files in os.walk(root, followlinks=False, onerror=raise_error):
        for name in sorted(dirs + files):
            path = Path(directory, name)
            if name == ".git" or not path.is_symlink():
                continue
            try:
                if path.resolve().is_relative_to(root):
                    continue
                issue = "external"
            except (OSError, RuntimeError):
                issue = "unresolvable"
            print(f"{issue}\t{path.relative_to(root)}")
            found = True
        dirs[:] = sorted(name for name in dirs if name != ".git"
                         and (args.all or name not in generated)
                         and not Path(directory, name).is_symlink())
    return int(found)


if __name__ == "__main__":
    raise SystemExit(main())
