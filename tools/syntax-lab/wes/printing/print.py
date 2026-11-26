from typing import IO, Any

from rich.console import Console

from wes.printing.theme import wes_theme


def make_console(file: IO[str] | None = None) -> Console:
    """A Console themed with Wes's palette; pass ``file=`` for other streams."""
    return Console(file=file, theme=wes_theme())


#: Module-level console that print() routes through (stdout, themed).
console = make_console()


def print(
    *objects: Any,
    sep: str = " ",
    end: str = "\n",
    file: IO[str] | None = None,
    flush: bool = False,
    **kwargs: Any,
) -> None:
    """Print like ``rich.print``, but with Wes's syntax-lab theme.

    Same signature as ``rich.print`` (``flush`` is accepted for
    builtin-print compatibility; Rich always flushes), plus any
    ``Console.print`` keyword (``style=``, ``highlight=``, ``markup=``, ...).
    """
    write_console = console if file is None else make_console(file=file)
    write_console.print(*objects, sep=sep, end=end, **kwargs)
