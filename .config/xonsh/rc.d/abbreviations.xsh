"""Visible command abbreviations backed by Xonsh's completion parser."""

import sys
from pathlib import Path


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from prompt_toolkit.filters import EmacsInsertMode, IsSearching, ViInsertMode
from xonsh.shells.ptk_shell.key_bindings import (
    carriage_return,
    should_confirm_completion,
)

from wes_abbreviations import AbbreviationRegistry
from wes_abbreviation_help import (
    abbreviation_help_alias,
    register_abbreviation_help,
)
from wes_abbreviation_list import abbreviation_list_alias
from wes_xonsh_abbreviations import (
    XonshAbbreviationExpander,
    expand_abbreviation_on_space,
)


XONSH_ABBREVIATIONS = AbbreviationRegistry()
register_abbreviation_help(XONSH_ABBREVIATIONS)
aliases["_abbr_help"] = lambda args, **kwargs: abbreviation_help_alias(
    XONSH_ABBREVIATIONS, args, **kwargs
)


def _abbr_list_alias(args, stdout=None):
    return abbreviation_list_alias(XONSH_ABBREVIATIONS, args, stdout=stdout)


aliases["_abbr_list"] = _abbr_list_alias

_wes_abbreviation_expander = XonshAbbreviationExpander(XONSH_ABBREVIATIONS)


def _expand_xonsh_abbreviation(buffer):
    return _wes_abbreviation_expander.expand(buffer)


@events.on_ptk_create
def _wes_abbreviation_keybindings(bindings, **_):
    @bindings.add(" ")
    def _expand_abbreviation_on_space(event):
        # Prompt Toolkit snapshots once before this handler, so replacement and
        # delimiter insertion are undone together.
        expand_abbreviation_on_space(
            event.current_buffer, _wes_abbreviation_expander
        )

    _insert_mode = ViInsertMode() | EmacsInsertMode()
    _submit_filter = (
        _insert_mode
        & ~IsSearching()
        & ~should_confirm_completion
    )

    @bindings.add("c-j", filter=_submit_filter, eager=True)
    @bindings.add("c-m", filter=_submit_filter, eager=True)
    def _expand_abbreviation_on_enter(event):
        _expand_xonsh_abbreviation(event.current_buffer)
        # AI autosuggestions are disposable prompt decoration. If that module
        # is loaded, keep its network request out of command submission's
        # critical path. This runs after expansion so `gst` still submits as
        # `git status`, while no request starts for the expanded text.
        cancel_ai = globals().get("_cancel_ai_autosuggestion_for_submit")
        if cancel_ai is not None:
            cancel_ai(event.current_buffer)
        carriage_return(event.current_buffer, event.cli)
