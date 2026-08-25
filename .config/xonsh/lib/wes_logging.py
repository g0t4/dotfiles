"""One shared logging destination for all Xonsh Python and XSH components."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import TextIO

from rich.console import Console
from rich.logging import RichHandler


DEFAULT_LOG_PATH = Path.home() / ".local/state/xonsh/xonsh.log"
ITERM_CLEAR_SCROLLBACK = "\x1b]1337;ClearScrollback\x07"

_root_logger = logging.getLogger("xonsh")
_root_logger.setLevel(logging.INFO)
_root_logger.propagate = False
_handler: logging.Handler | None = None
_stream: TextIO | None = None
_log_path: Path | None = None
_rich_output: bool | None = None
_cleared_paths: set[Path] = set()


def configure_logging(
    path: str | Path = DEFAULT_LOG_PATH,
    *,
    clear_iterm_scrollback: bool = False,
    rich_output: bool | str = True,
) -> logging.Logger:
    """Configure every ``xonsh.*`` logger to append to the same file."""
    global _handler, _log_path, _rich_output, _stream

    if isinstance(rich_output, str):
        rich_output = rich_output.lower() not in {"0", "false", "no", "off"}
    resolved = Path(path).expanduser().resolve()
    resolved.parent.mkdir(parents=True, exist_ok=True)
    if (
        _handler is None
        or _log_path != resolved
        or _rich_output != rich_output
    ):
        if _handler is not None:
            _root_logger.removeHandler(_handler)
            _handler.close()
        if _stream is not None:
            _stream.close()
        _stream = resolved.open("a", encoding="utf-8", buffering=1)
        if rich_output:
            console = Console(
                file=_stream,
                force_terminal=True,
                color_system="truecolor",
                soft_wrap=True,
                width=4096,
            )
            _handler = RichHandler(
                console=console,
                show_time=False,
                show_level=True,
                show_path=False,
                rich_tracebacks=True,
            )
            _handler.setFormatter(logging.Formatter("%(name)s %(message)s"))
        else:
            _handler = logging.StreamHandler(_stream)
            _handler.setFormatter(
                logging.Formatter(
                    "%(asctime)s %(levelname)s %(name)s %(message)s"
                )
            )
        _root_logger.addHandler(_handler)
        _log_path = resolved
        _rich_output = rich_output

    if clear_iterm_scrollback and resolved not in _cleared_paths:
        assert _stream is not None
        _stream.write(ITERM_CLEAR_SCROLLBACK)
        _stream.flush()
        _cleared_paths.add(resolved)
    return _root_logger


def get_logger(component: str) -> logging.Logger:
    """Return a component logger routed through the shared ``xonsh`` logger."""
    return logging.getLogger(f"xonsh.{component}")
