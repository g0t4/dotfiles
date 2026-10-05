from pathlib import Path
from xonsh.built_ins import XSH

from wes_abbreviations import abbr, reminder_abbr

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



# * dotfiles python "cmdlets"
$_python3 = f"{$WES_DOTFILES}/.venv/bin/python3"
#
XSH.aliases["hexdump"] = [$_python3, f"{$WES_DOTFILES}/.config/xonsh/apps/hex.py"]
XSH.aliases["ascii_table"] = [$_python3, f"{$WES_DOTFILES}/.config/xonsh/apps/ascii_table.py"]
#
# * cleanup
del $_python3

# PRN use a function and wrap in @() if not in command position?
#  btw show the method to get to it as I want to learn/habituate using shutil (not just calculate and show the values)
reminder_abbr('$LINES', 'shutil.get_terminal_size().lines', position="anywhere")
reminder_abbr('$ROWS', 'shutil.get_terminal_size().lines', position="anywhere")
reminder_abbr('$COLUMNS', 'shutil.get_terminal_size().columns', position="anywhere")

