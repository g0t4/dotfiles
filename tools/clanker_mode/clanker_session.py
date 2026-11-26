"""Compatibility imports for the shared append-only session implementation."""

import sys
from pathlib import Path

# Runtime Xonsh may have installed Clanker's dependencies before this package
# existed. Resolve shared source from the checkout, just like the startup hook.
# TODO install wes_package into my xonsh venv (uv tool) and then xonsh in dotfiles already has wes_package installed
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "wes_package"))
from wes.ai.session import (  # noqa: F401
    Session,
    _create_trace_file,
    get_session,
    serialize_message,
    timestamp,
)
