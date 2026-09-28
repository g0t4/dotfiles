"""Resolve Fish from Xonsh's active environment, not stale Python PATH state."""

from __future__ import annotations

import os
import shutil
from collections.abc import Iterable


def _xonsh_path() -> Iterable[str]:
    try:
        from xonsh.built_ins import XSH

        return XSH.env.get("PATH", ())
    except (AttributeError, ImportError, TypeError):
        return ()


def find_fish() -> str:
    xonsh_path = _xonsh_path()
    live_path = os.pathsep.join(map(str, xonsh_path))
    executable = shutil.which("fish", path=live_path) if live_path else None
    if executable:
        return executable

    known_paths = (
        "/opt/homebrew/bin/fish",
        "/usr/bin/fish",
    ),
    for path in known_paths:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    # now that I set syncing of env vars this helper is mostly unnecessary but I do like that it gives me the chance to expressly format a message when we fail to find fish
    raise FileNotFoundError("fish executable not found in Xonsh PATH, process PATH, or standard locations")
