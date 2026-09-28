from pathlib import Path
from xonsh.built_ins import XSH

from wes_abbreviations import abbr

if Path(__file__).name < "xonsh-only.xsh":
    raise RuntimeError("xonsh-only.xsh must be named so it loads later on to override with xonsh specific abbrs")

# * history overrides
# abbr hf 'history flush' # randomly this will not flush for 5+ minutes, not sure WTF is going on other than it is async and not guaranteed
#  so use at_exit=False to hopefully avoid this issue:
abbr('hf', '@.history.flush(at_exit=False)')
abbr('hp', 'history pull --show-commands')

# load Lexer by default so it is available, I suspect I'll use this alot
from xonsh.parsers.lexer import Lexer
# Lexer().split('echo "hello world" file.txt')
abbr('lexer_split', 'Lexer().split("%")', cursor_marker="%", reminder=True)



# # abbr('at', 'ascii_table')
# def ascii_table():
#     $_python3 = f"{$WES_DOTFILES}/.venv/bin/python3"
#     $_script_py = f"{$WES_DOTFILES}/.config/xonsh/apps/ascii_table.py"
#     $_python3 $_script_py

$_python3 = f"{$WES_DOTFILES}/.venv/bin/python3"
$_script_py = f"{$WES_DOTFILES}/.config/xonsh/apps/ascii_table.py"
XSH.aliases["ascii_table"] = [$_python3, $_script_py]
del $_python3
del $_script_py
