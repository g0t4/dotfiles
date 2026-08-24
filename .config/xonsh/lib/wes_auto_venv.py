"""Automatically select a parent directory's Python virtual environment."""

from __future__ import annotations

import os
from collections.abc import MutableMapping
from pathlib import Path
from typing import Any


VENV_DIRECTORY_NAMES = (".venv.local", ".venv")


def find_venv(start_directory: str | os.PathLike[str]) -> Path | None:
    """Return the nearest .venv.local or .venv at or above start_directory."""
    directory = Path(start_directory).expanduser().resolve()
    for parent in (directory, *directory.parents):
        for name in VENV_DIRECTORY_NAMES:
            candidate = parent / name
            if candidate.exists():
                return candidate
    return None


class AutoVenv:
    """Apply virtual-environment variables while retaining the original PATH."""

    def __init__(self, env: MutableMapping[str, Any]):
        self.env = env
        inherited_venv = env.get("VIRTUAL_ENV")
        inherited_bin = str(Path(inherited_venv) / "bin") if inherited_venv else None
        self.base_path = [
            str(entry)
            for entry in env.get("PATH", [])
            if str(entry) != inherited_bin
        ]
        self.active_venv: Path | None = None

    def update(self, directory: str | os.PathLike[str]) -> Path | None:
        """Activate the applicable venv, or restore PATH when none applies."""
        venv = find_venv(directory)
        if venv == self.active_venv:
            return venv

        self.deactivate()
        if venv is None:
            return None

        bin_directory = venv / "bin"
        if not bin_directory.is_dir():
            print(f"Missing venv bin directory:\n  {bin_directory}")
            return None

        self.env["PATH"] = [str(bin_directory), *self.base_path]
        self.env["VIRTUAL_ENV"] = str(venv)
        self.env["VIRTUAL_ENV_DISABLE_PROMPT"] = True
        self.active_venv = venv
        return venv

    def deactivate(self) -> None:
        """Undo this manager's activation, including an inherited venv."""
        self.env["PATH"] = self.base_path.copy()
        self.env.pop("VIRTUAL_ENV", None)
        self.env.pop("VIRTUAL_ENV_PROMPT", None)
        self.active_venv = None
