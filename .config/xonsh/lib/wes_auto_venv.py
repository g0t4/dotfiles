"""Automatically select a parent directory's Python virtual environment."""

from __future__ import annotations

import logging
import os
from collections.abc import MutableMapping
from pathlib import Path
from typing import Any

from wes_logging import get_logger


VENV_DIRECTORY_NAMES = (".venv.local", ".venv")
log = get_logger("auto_venv")
log.setLevel(logging.ERROR) # only failures (effectively shuts up the logger)
# log.setLevel(logging.NOTSET) # inherit
# log.setLevel(logging.INFO)


def _path_changes(before, after):
    return (
        [entry for entry in after if entry not in before],
        [entry for entry in before if entry not in after],
    )


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
        log.info(
            "initialized inherited_venv=%r base_path=%r",
            inherited_venv,
            self.base_path,
        )

    def update(self, directory: str | os.PathLike[str]) -> Path | None:
        """Activate the applicable venv, or restore PATH when none applies."""
        venv = find_venv(directory)
        log.info(
            "update directory=%r detected_venv=%r active_venv=%r",
            str(directory),
            str(venv) if venv else None,
            str(self.active_venv) if self.active_venv else None,
        )
        if venv == self.active_venv:
            log.info("unchanged venv=%r", str(venv) if venv else None)
            return venv

        self.deactivate()
        if venv is None:
            return None

        bin_directory = venv / "bin"
        if not bin_directory.is_dir():
            log.error("missing_bin directory=%r", str(bin_directory))
            print(f"Missing venv bin directory:\n  {bin_directory}")
            return None

        before_path = [str(entry) for entry in self.env.get("PATH", [])]
        self.env["PATH"] = [str(bin_directory), *self.base_path]
        self.env["VIRTUAL_ENV"] = str(venv)
        self.env["VIRTUAL_ENV_DISABLE_PROMPT"] = True
        self.active_venv = venv
        after_path = [str(entry) for entry in self.env.get("PATH", [])]
        added, removed = _path_changes(before_path, after_path)
        log.info(
            "activated venv=%r path_added=%r path_removed=%r path=%r",
            str(venv),
            added,
            removed,
            after_path,
        )
        return venv

    def deactivate(self) -> None:
        """Undo this manager's activation, including an inherited venv."""
        before_path = [str(entry) for entry in self.env.get("PATH", [])]
        previous_venv = self.env.get("VIRTUAL_ENV")
        self.env["PATH"] = self.base_path.copy()
        self.env.pop("VIRTUAL_ENV", None)
        self.env.pop("VIRTUAL_ENV_PROMPT", None)
        self.active_venv = None
        after_path = [str(entry) for entry in self.env.get("PATH", [])]
        added, removed = _path_changes(before_path, after_path)
        log.info(
            "deactivated venv=%r path_added=%r path_removed=%r path=%r",
            previous_venv,
            added,
            removed,
            after_path,
        )
