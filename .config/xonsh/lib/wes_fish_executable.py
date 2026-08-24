"""Resolve Fish from Xonsh's active environment, not stale Python PATH state."""

from __future__ import annotations

import os
import shutil
from collections.abc import Iterable


def _live_xonsh_path() -> Iterable[str]:
    try:
        from xonsh.built_ins import XSH

        return XSH.env.get("PATH", ())
    except (AttributeError, ImportError, TypeError):
        return ()


def find_fish(
    xonsh_path: Iterable[str] | None = None,
    *,
    process_path: str | None = None,
    standard_paths: Iterable[str] = (
        "/opt/homebrew/bin/fish",
        "/usr/local/bin/fish",
    ),
) -> str:
    """Return Fish's absolute executable path using shell-aware precedence."""
    live_entries = _live_xonsh_path() if xonsh_path is None else xonsh_path
    live_path = os.pathsep.join(map(str, live_entries))
    executable = shutil.which("fish", path=live_path) if live_path else None
    if executable:
        return executable

    inherited_path = os.environ.get("PATH", "") if process_path is None else process_path
    executable = shutil.which("fish", path=inherited_path) if inherited_path else None
    if executable:
        return executable

    for path in standard_paths:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    raise FileNotFoundError(
        "fish executable not found in Xonsh PATH, process PATH, or standard locations"
    )
