"""Wes's personal Python toolbox.

    from tools.wes import print

    print({"key": 42})  # themed via the syntax-lab palette
"""

from .print import console, make_console, print
from .theme import wes_theme

__all__ = ["console", "make_console", "print", "wes_theme"]
