"""Visible command abbreviations backed by Xonsh's completion parser."""

import sys
from pathlib import Path


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from prompt_toolkit.filters import EmacsInsertMode, IsMultiline, IsSearching, ViInsertMode
from xonsh.shells.ptk_shell.key_bindings import (
    carriage_return,
    should_confirm_completion,
)

from wes_abbreviations import AbbreviationRegistry
from wes_xonsh_abbreviations import XonshAbbreviationExpander


XONSH_ABBREVIATIONS = AbbreviationRegistry()

_wes_abbreviation_expander = XonshAbbreviationExpander(XONSH_ABBREVIATIONS)


def _expand_xonsh_abbreviation(buffer):
    return _wes_abbreviation_expander.expand(buffer)


@events.on_ptk_create
def _wes_abbreviation_keybindings(bindings, **_):
    @bindings.add(" ")
    def _expand_abbreviation_on_space(event):
        # Prompt Toolkit snapshots once before this handler, so replacement and
        # delimiter insertion are undone together.
        _expand_xonsh_abbreviation(event.current_buffer)
        event.current_buffer.insert_text(" ")

    _insert_mode = ViInsertMode() | EmacsInsertMode()
    _submit_filter = (
        IsMultiline()
        & _insert_mode
        & ~IsSearching()
        & ~should_confirm_completion
    )

    @bindings.add("c-j", filter=_submit_filter)
    @bindings.add("c-m", filter=_submit_filter)
    def _expand_abbreviation_on_enter(event):
        _expand_xonsh_abbreviation(event.current_buffer)
        carriage_return(event.current_buffer, event.cli)
