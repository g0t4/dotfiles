# *** ag color options ***
#   also uses ansi color codes like GREP
#   options:
#     --color-line-number # Default is 1;33. (fg: bold, yellow)
#     --color-match # Default is 30;43. (fg: default, bg: yellow)
#     --color-path # Default is 1;32. (fg: bold, green)
#

# FYI colors are defined by fish/zsh respectively in color-specific.{fish,zsh}
alias ag='ag --nogroup --color-match "$color_matching_text"'
# FYI can defer expand color variable so order of startup files is irrelevant
# --nogroup => disable grouping to show file/line per match to click to open in vscode (via iterm links)

ealias agi="ag -i"
ealias agh="ag --hidden" # search hidden files (including vcs ignores)
ealias agu="ag -u" # unrestricted # by default .gitignore/.hgignore/.ignore are excluded

# I am used to these params, don't currently need to alias them:
#  -g and -G myself
#  -A/-B or -C # num of context lines to show # default = 2 for both

ealias agl="ag -l" # print file name only, not matched content
ealias agL="ag -L" # print files w/o content match
ealias agw="ag --word-regexp" # match whole words
ealias agz="ag --search-zip" # search inside zip files (gz,xz only)
