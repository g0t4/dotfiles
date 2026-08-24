"""Pure state and buffer helpers for the native Xonsh FZF pickers."""

from __future__ import annotations

import hashlib
import os
import shlex
import tempfile
from pathlib import Path
from typing import Iterable


class FzfMru:
    def __init__(self, root: Path | None = None, cap: int = 30):
        self.root = root or Path("~/.cache/fzf-mru").expanduser()
        self.cap = cap

    @staticmethod
    def key(cwd: Path) -> str:
        # Fish computes `pwd | shasum`; echo contributes the trailing newline.
        return hashlib.sha1(f"{cwd}\n".encode()).hexdigest()

    def path(self, picker: str, cwd: Path) -> Path:
        directory = self.root / picker
        directory.mkdir(parents=True, exist_ok=True)
        path = directory / self.key(cwd)
        path.touch(exist_ok=True)
        return path

    def read(self, picker: str, cwd: Path) -> list[str]:
        path = self.path(picker, cwd)
        return [
            value
            for value in path.read_text().splitlines()
            if (cwd / value).exists()
        ]

    def record(self, picker: str, selected: str, cwd: Path) -> None:
        selected = os.path.normpath(selected)
        path = self.path(picker, cwd)
        previous = [value for value in path.read_text().splitlines() if value != selected]
        values = [selected, *previous][: self.cap]
        descriptor, temporary = tempfile.mkstemp(dir=path.parent, prefix=".mru-")
        try:
            with os.fdopen(descriptor, "w") as stream:
                stream.write("".join(f"{value}\n" for value in values))
            os.replace(temporary, path)
        finally:
            Path(temporary).unlink(missing_ok=True)


def ordered_candidates(mru: Iterable[str], fresh: Iterable[str]) -> list[str]:
    result: list[str] = []
    seen: set[str] = set()
    for value in (*mru, *fresh):
        if value and value not in seen:
            result.append(value)
            seen.add(value)
    return result


def parse_git_ref_token(token: str) -> tuple[str | None, str]:
    if ":" not in token:
        return None, token
    git_ref, path = token.split(":", 1)
    # Keep Fish's deliberate omission of index forms such as :README.
    if not git_ref:
        return None, token
    return git_ref, path


def apply_path_selection(
    buffer: str,
    token_start: int,
    token_end: int,
    selected: str | None,
    *,
    git_ref: str | None = None,
) -> tuple[str, int]:
    if not selected:
        return buffer, token_end
    value = f"{git_ref}:{selected}" if git_ref else selected
    escaped = shlex.quote(value)
    updated = buffer[:token_start] + escaped + buffer[token_end:]
    return updated, token_start + len(escaped)
