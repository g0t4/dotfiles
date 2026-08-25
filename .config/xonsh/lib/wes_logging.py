"""One shared logging destination for all Xonsh Python and XSH components."""

from __future__ import annotations

import logging
from pathlib import Path


DEFAULT_LOG_PATH = Path.home() / ".local/state/xonsh/xonsh.log"
ITERM_CLEAR_SCROLLBACK = "\x1b]1337;ClearScrollback\x07"

_root_logger = logging.getLogger("xonsh")
_root_logger.setLevel(logging.INFO)
_root_logger.propagate = False
_handler: logging.FileHandler | None = None
_log_path: Path | None = None
_cleared_paths: set[Path] = set()


def configure_logging(
    path: str | Path = DEFAULT_LOG_PATH,
    *,
    clear_iterm_scrollback: bool = False,
) -> logging.Logger:
    """Configure every ``xonsh.*`` logger to append to the same file."""
    global _handler, _log_path

    resolved = Path(path).expanduser().resolve()
    resolved.parent.mkdir(parents=True, exist_ok=True)
    if _handler is None or _log_path != resolved:
        if _handler is not None:
            _root_logger.removeHandler(_handler)
            _handler.close()
        _handler = logging.FileHandler(resolved)
        _handler.setFormatter(
            logging.Formatter(
                "%(asctime)s %(levelname)s %(name)s %(message)s"
            )
        )
        _root_logger.addHandler(_handler)
        _log_path = resolved

    if clear_iterm_scrollback and resolved not in _cleared_paths:
        assert _handler is not None
        _handler.stream.write(ITERM_CLEAR_SCROLLBACK)
        _handler.flush()
        _cleared_paths.add(resolved)
    return _root_logger


def get_logger(component: str) -> logging.Logger:
    """Return a component logger routed through the shared ``xonsh`` logger."""
    return logging.getLogger(f"xonsh.{component}")
