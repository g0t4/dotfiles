"""One shared logging destination for all Xonsh Python and XSH components."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import TextIO

from rich.console import Console, Group


ITERM_CLEAR_SCROLLBACK = "\x1b]1337;ClearScrollback\x07"
LOG_RENDER_WIDTH = 100_000

_root_logger = logging.getLogger("xonsh")
_root_logger.setLevel(logging.INFO)
_root_logger.propagate = False
_handler: logging.Handler | None = None
_stream: TextIO | None = None
_log_path: Path | None = None
_cleared_paths: set[Path] = set()


def ensure_logger_is_setup():
    # TODO move to just call this once in entrypoint / shell config early on
    import os
    use_rich = os.getenv("XONSH_LOG_RICH") or True
    _configure_logging(
        clear_iterm_scrollback=True,
    )

DEFAULT_LOG_PATH = Path.home() / ".local/state/xonsh/xonsh.log"

def _configure_logging(
    path: str | Path = DEFAULT_LOG_PATH,
    *,
    clear_iterm_scrollback: bool = False,
) -> logging.Logger:
    """Configure every ``xonsh.*`` logger to append to the same file."""
    global _handler, _log_path, _stream, _console

    resolved = Path(path).expanduser().resolve()
    resolved.parent.mkdir(parents=True, exist_ok=True)
    if (
        _handler is None
        or _log_path != resolved
    ):
        if _handler is not None:
            _root_logger.removeHandler(_handler)
            _handler.close()
        if _stream is not None:
            _stream.close()
        _stream = resolved.open("a", encoding="utf-8", buffering=1)
        _console = Console(
            file=_stream,
            force_terminal=True,
            color_system="truecolor",
            no_color=False,
            soft_wrap=True,
            width=LOG_RENDER_WIDTH,
        )
        _handler = logging.StreamHandler(_stream)
        _handler.setFormatter(
            logging.Formatter("%(name)s %(message)s")
        )
        _root_logger.addHandler(_handler)
        _log_path = resolved

    if clear_iterm_scrollback and resolved not in _cleared_paths:
        assert _stream is not None
        _stream.write(ITERM_CLEAR_SCROLLBACK)
        _stream.flush()
        _cleared_paths.add(resolved)
    return _root_logger


def get_console():
    """
    Use this for rich console logging, just bypass logger entirely
    i.e. rich.inspect(thing, console=get_console())
    TODO I'd prefer to subclass logger and attach log.inspect() or log.inspect_info(...) with various levels
    this is going to be superior to having everything flow through rich most likely
    """
    if _console:
        return _console
    raise RuntimeError("Rich console not configured")


def get_logger(component: str) -> logging.Logger:
    """Return a component logger routed through the shared ``xonsh`` logger."""
    return logging.getLogger(f"xonsh.{component}")
