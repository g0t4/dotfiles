"""Ctrl-S searches the Tab menu; Alt-D toggles descriptions beside choices."""

from xonsh.built_ins import XSH
from xonsh.events import events
from wes_completion_menu import install_completion_menu


@events.on_ptk_create
def _wes_completion_menu(bindings, prompter=None, **_):
    install_completion_menu(prompter, bindings, XSH.env)
