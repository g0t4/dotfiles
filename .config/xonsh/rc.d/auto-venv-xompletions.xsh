"""Load native tool completions from global uv tools and the active auto-venv."""

import os

from xonsh.built_ins import XSH
from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import contextual_command_completer, tag_provider
from xonsh.events import events

from wes_xompletions import XompletionManager


_wes_xompletions = XompletionManager()
_wes_xompletions.update_local(@.env.get("VIRTUAL_ENV"))


@contextual_command_completer
def _wes_tool_xompletion(command):
    if command.arg_index == 0:
        return None
    command_name = os.path.basename(command.command)
    completions = _wes_xompletions.complete(command_name, command)
    if completions is None:
        return None
    return tag_provider(completions, command_name)


add_one_completer("wes_tool_xompletions", _wes_tool_xompletion, "start")


@events.on_chdir
def _wes_xompletions_on_chdir(**_):
    _wes_xompletions.update_local(@.env.get("VIRTUAL_ENV"))
