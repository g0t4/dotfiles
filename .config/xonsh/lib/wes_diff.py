"""Reusable pieces for comparing command output in Xonsh."""

from __future__ import annotations

import os
import shlex
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Callable, Iterable, Iterator


OutputWriter = Callable[[str, Path], None]


@contextmanager
def psub(commands: Iterable[str], writer: OutputWriter) -> Iterator[tuple[Path, ...]]:
    """Materialize command outputs as paths and remove them afterward.

    This is the deterministic-lifetime Xonsh equivalent of Fish's `psub` for
    Python aliases.  The writer keeps command execution policy outside this
    small, testable resource-management primitive.
    """
    paths: list[Path] = []
    try:
        for command in commands:
            descriptor, raw_path = tempfile.mkstemp(prefix="xonsh-psub-")
            os.close(descriptor)
            path = Path(raw_path)
            paths.append(path)
            writer(command, path)
        yield tuple(paths)
    finally:
        for path in paths:
            path.unlink(missing_ok=True)


# Descriptive alias for callers that do not already know Fish's name.
command_output_files = psub


class ProcessSubstitutionFiles:
    """Track pipeline-backed tempfiles until Xonsh finishes the outer command."""

    def __init__(self):
        self.paths: list[Path] = []

    def from_stream(self, stream) -> Path:
        descriptor, raw_path = tempfile.mkstemp(prefix="xonsh-psub-")
        path = Path(raw_path)
        try:
            with os.fdopen(descriptor, "wb") as output:
                while chunk := stream.read(1024 * 1024):
                    if isinstance(chunk, str):
                        chunk = chunk.encode()
                    output.write(chunk)
        except BaseException:
            path.unlink(missing_ok=True)
            raise
        self.paths.append(path)
        return path

    def cleanup(self) -> None:
        paths, self.paths = self.paths, []
        for path in paths:
            path.unlink(missing_ok=True)


def last_commands(history: Iterable[str], count: int = 2) -> tuple[str, ...]:
    commands = [
        command.removesuffix("\n") for command in history if command.strip()
    ]
    return tuple(commands[-count:])


def diff_expansion(history: Iterable[str], suffix: str = "") -> str | None:
    commands = last_commands(history)
    if len(commands) != 2:
        return None
    return "diff_two_commands " + " ".join(
        shlex.quote(command + suffix) for command in commands
    )


def sanitize_icdiff_label(command: str) -> str:
    # icdiff treats braces in -L labels as {path}/{basename} interpolation.
    return command.replace("{", "_").replace("}", "_")


def copied_patch_sides(patch: str) -> tuple[str, str]:
    """Return apply-patch text without removals and without additions."""
    lines = patch.splitlines(keepends=True)
    return (
        "".join(line for line in lines if not line.startswith("-")),
        "".join(line for line in lines if not line.startswith("+")),
    )
