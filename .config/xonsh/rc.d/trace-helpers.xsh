"""Trace viewing, annotation, and RAG CLI helpers from Fish."""

from xonsh.built_ins import XSH
from pathlib import Path
from xonsh.completers.completer import add_one_completer
from xonsh.completers.path import complete_dir
from xonsh.completers.tools import RichCompletion, contextual_command_completer
from wes_trace_helpers import register_trace_helpers

register_trace_helpers(XSH.aliases, $WES_DOTFILES)


@contextual_command_completer
def _trace_helper_completer(command):
    if command.command == "browse_traces" and command.arg_index == 1:
        root = Path($WES_ASK_CAPTURES)
        if not root.is_dir():
            return set()
        return {
            RichCompletion(path.name, prefix_len=len(command.prefix), append_space=True,
                           description="Trace collection", provider="trace-helpers")
            for path in root.iterdir()
            if path.is_dir() and path.name.startswith(command.prefix)
        }
    if command.command == "mcp_server_semantic_grep" and command.arg_index > 0:
        if command.args[command.arg_index - 1].value == "--root-dir":
            return complete_dir(command)
        return {
            RichCompletion("--root-dir", prefix_len=len(command.prefix), append_space=True,
                           description="Root directory for semantic grep", provider="trace-helpers")
        } if "--root-dir".startswith(command.prefix) else set()
    return None


add_one_completer("trace_helpers", _trace_helper_completer, "start")
