"""Use jethrokuan/z's Fish implementation and shared directory database."""

from __future__ import annotations

import subprocess
import sys
from collections.abc import Callable, Sequence
from pathlib import Path

from wes_fish_executable import find_fish


class FishZError(RuntimeError):
    pass


class FishZ:
    """Resolve and record directories through Fish's authoritative z plugin."""

    def __init__(
        self,
        runner: Callable = subprocess.run,
        timeout: float = 5.0,
        fish_executable: str | None = None,
    ):
        self.runner = runner
        self.timeout = timeout
        self.fish_executable = fish_executable

    def _fish(self) -> str:
        return self.fish_executable or find_fish()

    def resolve(self, args: Sequence[str]) -> Path:
        try:
            completed = self.runner(
                [self._fish(), "-c", '__z --echo "$argv"', "--", *map(str, args)],
                capture_output=True,
                text=True,
                timeout=self.timeout,
            )
        except (OSError, subprocess.TimeoutExpired) as error:
            raise FishZError(f"could not query Fish z: {error}") from error
        output = completed.stdout.strip()
        if completed.returncode:
            detail = output or completed.stderr.strip() or "no matching directory"
            raise FishZError(detail)

        destination = Path(output).expanduser()
        if not destination.is_dir():
            raise FishZError(f"z result is not a directory: {destination}")
        return destination

    def run(
        self,
        args: Sequence[str],
        cwd: str | Path | None = None,
        stdin=None,
        stdout=None,
        stderr=None,
    ):
        """Run a non-jumping z operation and preserve its output and status."""
        return self.runner(
            [self._fish(), "-c", '__z "$argv"', "--", *map(str, args)],
            cwd=cwd,
            stdin=stdin,
            stdout=stdout,
            stderr=stderr,
            text=True,
            timeout=self.timeout,
        )

    def record(self, directory: str | Path) -> bool:
        try:
            completed = self.runner(
                [self._fish(), "-c", "__z_add"],
                cwd=Path(directory),
                capture_output=True,
                text=True,
                timeout=self.timeout,
            )
        except (OSError, subprocess.TimeoutExpired) as error:
            print(f"z: failed to record {directory}: {error}", file=sys.stderr)
            return False
        if completed.returncode:
            detail = completed.stderr.strip() or completed.stdout.strip()
            print(f"z: failed to record {directory}: {detail}", file=sys.stderr)
            return False
        return True
