### *** ANSI COLOR CODES (ensure sync w/ color-specific.zsh)
# 8-bit lookup table: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
color_191="38;5;191"
color_matching_text="1;$color_191"
#

# *** grep colors and options:
GREP_OPTIONS='--color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'

# PRN limit this to macOS only (like in color-specific.fish) => how about wait and see how this behaves in other envs (ie linux)
export GREP_COLOR="$color_matching_text" # cannot defer expand color variable

alias grep="grep $GREP_OPTIONS"

# *** next:
