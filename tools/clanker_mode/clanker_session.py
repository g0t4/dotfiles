"""Compatibility imports for the shared append-only session implementation."""

import sys
from pathlib import Path

# Runtime Xonsh may have installed Clanker's dependencies before this package
# existed. Resolve shared source from the checkout, just like the startup hook.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "ai_shared"))
from ai_shared.session import (  # noqa: F401
    Session,
    _create_trace_file,
    get_session,
    serialize_message,
    timestamp,
)
