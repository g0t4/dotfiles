"""GH CLI abbreviations and direct bridges to the existing Zsh gitignore tools."""

import subprocess
from xonsh.built_ins import XSH
from xonsh.completers.completer import add_one_completer
from xonsh.completers.tools import RichCompletion, contextual_command_completer
from wes_gh_tool_abbreviations import register_gh_abbreviations
from wes_gitignore_tool_abbreviations import SOURCE_FUNCTIONS, register_gitignore_abbreviations
from wes_daily_tool_bridges import zsh_alias, gitignore_templates

register_gh_abbreviations()
register_gitignore_abbreviations()
for _gitignore_function in SOURCE_FUNCTIONS:
    XSH.aliases[_gitignore_function] = zsh_alias(_gitignore_function)


@contextual_command_completer
def _gitignore_completer(command):
    if command.command not in {"gitignores_for", "append_gitignores_for", "commit_gitignores_for", "gi", "gia", "gic"}:
        return None
    if command.arg_index < 1:
        return None
    prefix = command.prefix.rsplit(",", 1)[-1]
    try:
        templates = gitignore_templates()
    except (OSError, subprocess.SubprocessError):
        return set()
    return {RichCompletion(name, prefix_len=len(prefix), append_space=False,
                           description="gitignore template", provider="gitignore")
            for name in templates if name.startswith(prefix)}


add_one_completer("gitignore", _gitignore_completer, "start")
