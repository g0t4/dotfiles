### *** ANSI COLOR CODES (ensure sync w/ color-specific.zsh)
# 8-bit lookup table: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
__color_bold="1"
__color_99="38;5;99"
__color_162="38;5;162"
__color_191="38;5;191"
__color_200="38;5;200"
__color_matching_text="$__color_bold;$__color_162"
#

# *** grep colors and options:
GREP_OPTIONS='--color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'

# PRN limit this to macOS only (like in color-specific.fish) => how about wait and see how this behaves in other envs (ie linux)
export GREP_COLOR="$__color_matching_text" # cannot defer expand color variable

alias grep="grep $GREP_OPTIONS"

# *** next:
