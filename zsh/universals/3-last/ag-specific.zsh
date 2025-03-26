# *** ag color options ***
#   also uses ansi color codes like GREP
#   options:
#     --color-line-number # Default is 1;33. (fg: bold, yellow)
#     --color-match # Default is 30;43. (fg: default, bg: yellow)
#     --color-path # Default is 1;32. (fg: bold, green)
#

# FYI colors are defined by fish/zsh respectively in color-specific.{fish,zsh}
alias ag='ag --nogroup --color-match "$__color_matching_text"'
# FYI can defer expand color variable so order of startup files is irrelevant
# --nogroup => disable grouping to show file/line per match to click to open in vscode (via iterm links)

abbr agi 'ag -i'
abbr agig 'ag -ig'
abbr agh 'ag --hidden -i'
abbr agu 'ag -u'

# I am used to these params, don't currently need to alias them:
#  -g and -G myself
#  -A/-B or -C # num of context lines to show # default = 2 for both

abbr agl 'ag -l' # print file name only, not matched content
abbr agL 'ag -L' # print files w/o content match
abbr agw 'ag --word-regexp' # match whole words
abbr agz 'ag --search-zip' # search inside zip files (gz,xz only)
abbr agfiles 'ag -g ""'  # show all files that would be searched, like rg's --files

# *** rg (start to consider using this?)
abbr rgi 'rg -i' # same as -i in ag
# abbr rgig # TODO equiv
abbr rgh 'rg --hidden -i'
abbr rgu 'rg -u' # unrestricted (not sure exactly the same as ag's unrestricted, has to be close)
abbr rgfiles 'rg --files' # list files that would be searched

abbr rgm 'rg --multiline --multiline-dotall' # dot as \n too

# shared args:
# -i to ignore case
# --hidden (note ag also uses -h whereas rg does not)
# -u/--unrestricteda (not 100% same, still some filtering in rg)
#
# *** FYI use these to find differences:
#   diff_two_commands 'ag -g \'\'| sort' 'rg --files | sort'
#   ag -g ''
#   rg --files
#   # diff there is gonna show differences in args
#

# cd dotfiles (this repo):
#   diff_two_commands 'rg --hidden -i telescope -l | sort' 'ag --hidden -i telescope -l | sort'
#     matches
#   diff_two_commands 'ag --unrestricted -i telescope -l | sort' 'rg --unrestricted -i telescope -l | sort'
#     does not match, far fewer matches from rg
#     notably --hidden files are gone
#     and binaries (libs)
