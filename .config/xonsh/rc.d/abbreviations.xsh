"""Visible command abbreviations backed by Xonsh's completion parser."""

import sys
from pathlib import Path


_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from wes_abbreviations import AbbreviationRegistry, abbr
from wes_xonsh_abbreviations import XonshAbbreviationExpander


XONSH_ABBREVIATIONS = AbbreviationRegistry()

# Declarations are objects, not dictionaries: callbacks and configuration use
# normal Python attributes such as context.command_path and result.cursor.
abbr(XONSH_ABBREVIATIONS, "gst", "git status")

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


# If Enter is pressed without a trailing delimiter, retain the command behavior
# even though there was no opportunity to visibly expand the buffer first.
aliases["gst"] = ["git", "status"]
