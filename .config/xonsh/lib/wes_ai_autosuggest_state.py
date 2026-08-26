"""Persistent user preference for Xonsh AI autosuggestions."""

from __future__ import annotations

import os
import tempfile
from collections.abc import Mapping
from pathlib import Path


def autosuggest_state_path(env: Mapping[str, object]) -> Path:
    override = env.get("XONSH_AI_AUTOSUGGEST_STATE")
    if override:
        return Path(str(override)).expanduser()
    state_home = env.get("XDG_STATE_HOME") or "~/.local/state"
    return Path(str(state_home)).expanduser() / "xonsh/ai-autosuggest"


def read_autosuggest_enabled(env: Mapping[str, object]) -> bool:
    try:
        value = autosuggest_state_path(env).read_text().strip().lower()
    except OSError:
        return True
    return value not in {"0", "false", "no", "off"}


def write_autosuggest_enabled(env: Mapping[str, object], enabled: bool) -> None:
    path = autosuggest_state_path(env)
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent, prefix=".autosuggest-")
    try:
        with os.fdopen(descriptor, "w") as stream:
            stream.write("on\n" if enabled else "off\n")
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)
