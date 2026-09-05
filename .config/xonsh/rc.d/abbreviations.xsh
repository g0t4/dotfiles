"""Visible command abbreviations backed by Xonsh's completion parser."""

import subprocess
import sys
from pathlib import Path

from rich.console import Console

_wes_xonsh_lib = Path($XONSH_CONFIG_DIR) / "lib"
if str(_wes_xonsh_lib) not in sys.path:
    sys.path.insert(0, str(_wes_xonsh_lib))

from prompt_toolkit.application import run_in_terminal
from prompt_toolkit.filters import EmacsInsertMode, IsSearching, ViInsertMode
from prompt_toolkit.input import ansi_escape_sequences
from prompt_toolkit.input.vt100_parser import _IS_PREFIX_OF_LONGER_MATCH_CACHE
from prompt_toolkit.keys import Keys
from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import (
    RichCompletion,
    contextual_command_completer,
    non_exclusive_completer,
)
from xonsh.shells.ptk_shell.key_bindings import (
    carriage_return,
    should_confirm_completion,
)

import wes_abbreviations
from wes_abbreviation_help import (
    abbreviation_help_alias,
    register_abbreviation_help,
)
from wes_abbreviation_list import abbreviation_list_alias
from wes_xonsh_abbreviations import (
    XonshAbbreviationExpander,
    abbreviation_completion_candidates,
    abbreviation_picker_rows,
    apply_abbreviation_selection,
    context_from_completion,
    expand_abbreviation_on_space,
)

from wes_logging import ensure_logger_is_setup, get_logger, get_console
ensure_logger_is_setup()
log = get_logger("abbrs")

register_abbreviation_help()
aliases["_abbr_help"] = lambda args, **kwargs: abbreviation_help_alias(
    wes_abbreviations.XONSH_ABBREVIATIONS, args, **kwargs
)


def _abbr_list_alias(args, stdout=None, spec=None):
    # import rich
    # rich.inspect(stdout, console=get_console()) # FYI stdout from xonsh is _io.TextIOWrapper
    # rich.inspect(spec, console=get_console())
    use_color = spec is not None and spec.last_in_pipeline
    console = Console(file=stdout, force_terminal=use_color)
    return abbreviation_list_alias(
        wes_abbreviations.XONSH_ABBREVIATIONS, args, console
    )


aliases["_abbr_list"] = _abbr_list_alias

_wes_abbreviation_expander = XonshAbbreviationExpander(wes_abbreviations.XONSH_ABBREVIATIONS)


@non_exclusive_completer
@contextual_command_completer
def _wes_abbreviation_completer(command):
    context = context_from_completion(
        command.prefix + command.suffix,
        len(command.prefix),
        command,
    )
    return {
        RichCompletion(
            trigger,
            prefix_len=len(command.prefix),
            description=expansion,
            append_space=False,
            provider="abbreviation",
        )
        for trigger, expansion in abbreviation_completion_candidates(
            wes_abbreviations.XONSH_ABBREVIATIONS, context
        )
    }


add_one_completer("wes_abbreviations", _wes_abbreviation_completer, "start")


# Enhanced keyboard protocols encode Alt-Shift-A as one CSI sequence instead
# of the legacy Escape + A pair Prompt Toolkit expects.
for _abbr_picker_codepoint in (ord("A"), ord("a")):
    ansi_escape_sequences.ANSI_SEQUENCES[
        f"\x1b[{_abbr_picker_codepoint};4u"
    ] = (Keys.Escape, "A")
    ansi_escape_sequences.ANSI_SEQUENCES[
        f"\x1b[27;4;{_abbr_picker_codepoint}~"
    ] = (Keys.Escape, "A")
_IS_PREFIX_OF_LONGER_MATCH_CACHE.clear()


def _run_abbreviation_picker(rows, query):
    completed = subprocess.run(
        [
            "fzf",
            "--height",
            "50%",
            "--border",
            "--delimiter=\t",
            "--with-nth=1,2",
            "--accept-nth=1",
            "--header",
            "Choose trigger  |  then Space expands  |  Enter runs",
            "--query",
            query,
        ],
        input="".join(f"{row}\n" for row in rows),
        stdout=subprocess.PIPE,
        text=True,
        env=${...}.detype(),
    )
    return completed.stdout.rstrip("\n") if completed.returncode == 0 else None


async def _abbreviation_picker_handler(event):
    buffer = event.current_buffer
    context = _wes_abbreviation_expander.context(buffer)
    if context is None:
        return
    rows = abbreviation_picker_rows(wes_abbreviations.XONSH_ABBREVIATIONS, context)
    selected = await run_in_terminal(
        lambda: _run_abbreviation_picker(rows, context.token)
    )
    if selected:
        buffer.text, buffer.cursor_position = apply_abbreviation_selection(
            buffer.text,
            context.token_start,
            context.token_end,
            selected,
        )
    event.app.invalidate()


def _expand_xonsh_abbreviation(buffer):
    return _wes_abbreviation_expander.expand(buffer)


@events.on_ptk_create
def _wes_abbreviation_keybindings(bindings, **_):
    _insert_mode = ViInsertMode() | EmacsInsertMode()
    bindings.add("escape", "A", filter=_insert_mode)(
        _abbreviation_picker_handler
    )

    @bindings.add(" ")
    def _expand_abbreviation_on_space(event):
        # Prompt Toolkit snapshots once before this handler, so replacement and
        # delimiter insertion are undone together.
        expand_abbreviation_on_space(
            event.current_buffer, _wes_abbreviation_expander
        )

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
