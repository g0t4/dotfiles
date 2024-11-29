# *** ag color options ***
#   also uses ansi color codes like GREP
#   options:
#     --color-line-number # Default is 1;33. (fg: bold, yellow)
#     --color-match # Default is 30;43. (fg: default, bg: yellow)
#     --color-path # Default is 1;32. (fg: bold, green)
#

# FYI colors are defined by fish/zsh respectively in color-specific.{fish,zsh}
function ag
  command ag --nogroup --color-match "$__color_matching_text" $argv
end
# FYI can defer expand color variable so order of startup files is irrelevant
# --nogroup => disable grouping to show file/line per match to click to open in vscode (via iterm links)

abbr --set-cursor='!' --  agi 'ag -i "!"'
abbr --set-cursor='!' --  agg 'ag -ig "!"'
abbr --set-cursor='!' --  agh 'ag --hidden -i "!"' # match hidden files, but not ignored files
abbr --set-cursor='!' --  aggh 'ag --hidden -ig "!"' # match hidden files, but not ignored files
abbr --set-cursor='!' --  agu 'ag --unrestricted -i "!"' # match hidden files + ignored files
abbr --set-cursor='!' --  aggu 'ag --unrestricted -ig "!"' # match hidden files + ignored files
# ignored files: .ignore, .gitignore, --ignore, etc
# hidden files: .config, .git (dotfiles/dirs)

# I am used to these params, don't currently need to alias them:
#  -g and -G myself
#  -A/-B or -C # num of context lines to show # default = 2 for both

abbr agl 'ag -l' # print file name only, not matched content
abbr agL 'ag -L' # print files w/o content match
abbr agw 'ag --word-regexp' # match whole words
abbr agz 'ag --search-zip' # search inside zip files (gz,xz only)
function agimages
    for f in (ag --unrestricted -i -g "\.(png|jpg|jpeg|gif|bmp|tiff|webp|svg|icns)")
        echo $f
        imgcat $f
    end
end
