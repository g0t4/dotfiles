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

abbr --set-cursor='!' -- agi 'ag -i "!"'
abbr --set-cursor='!' -- agg 'ag -ig "!"'
abbr --set-cursor='!' -- agh 'ag --hidden -i "!"' # match hidden files, but not ignored files
abbr --set-cursor='!' -- aggh 'ag --hidden -ig "!"' # match hidden files, but not ignored files
abbr --set-cursor='!' -- agu 'ag --unrestricted -i "!"' # match hidden files + ignored files
abbr --set-cursor='!' -- aggu 'ag --unrestricted -ig "!"' # match hidden files + ignored files
# ignored files: .ignore, .gitignore, --ignore, etc
# hidden files: .config, .git (dotfiles/dirs)

# I am used to these params, don't currently need to alias them:
#  -g and -G myself
#  -A/-B or -C # num of context lines to show # default = 2 for both

abbr agl 'ag -l' # print file name only, not matched content
abbr agL 'ag -L' # print files w/o content match
abbr agw 'ag --word-regexp' # match whole words
abbr agz 'ag --search-zip' # search inside zip files (gz,xz only)

abbr --set-cursor='!' agm 'ag "(?s)!"' # (?s) makes . match \n too
#  example:
#    ag -G fish "(?s)for[^(end)]*set[^(end)]*"
#       here I was looking for for loops that use `set -`, first just `set`
#       not sure this does what I want... it's hard to match across lines :) and not get crazy results
#    find all for loops that set a variable (before they end)

# ***rg (start to consider using this?)
abbr rgm 'rg --multiline --multiline-dotall' # dot as \n too






function agimages
    # usage:
    #   agimages /System/Library/CoreServices/ Picture
    #   agimages /System/Library/CoreServices/ Finder
    #   agimages /System/Library/CoreServices/ Movie

    set look_in_dir $argv[1] # optional
    set secondary_path_filter $argv[2]
    # cannot filter paths with -g and -G with ag command, so use grep as secondary filter to get subset of matching image files
    if test -z "$secondary_path_filter"
        set cmd "ag --unrestricted -i -g '\.(png|jpg|jpeg|gif|bmp|tiff|webp|svg|icns|ico)' $look_in_dir"
    else
        set cmd "ag --unrestricted -i -g '\.(png|jpg|jpeg|gif|bmp|tiff|webp|svg|icns|ico)' $look_in_dir | grep -i '$secondary_path_filter'"
    end

    for f in (eval $cmd)
        echo $f
        imgcat $f
    end

    # printf "\x1B]1337;File=name=Tray-Win32.ico;inline=1:$(cat Contents/Resources/Tray-Win32.ico | base64)\x07"
    #   width=100 paramerter is avail
    # imgcat uses iterm protocol extensions https://iterm2.com/documentation-images.html

    # https://iterm2.com/utilities/imgcat

    ## TODOS
    # TODO why does imgcat fail on some svgs? can I detect and avoid that? => look at ~/Applications/DataSpell.app/Contents/plugins/pycharm-ds-customization/jupyter-web/fontawesome-webfont.svg
    # TODO can I limit size of image?
end

function agimages-global
    # usage:
    #   agimages-global <search term>
    #   agimages-global MovieFolderIcon
    #   agimages-global FolderIcon
    #
    # FYI can take a while to search all the dirs but give it a second, esp paths that are later in the list:

    # FYI hold down Ctrl+C to stop the loop (will eventually work) dont tap it repeatedly

    #-- take a search term, find in common places, i.e. /Applications/X.app/*
    agimages /Applications "$argv"
    agimages ~/Applications "$argv"

    # TODO just adding this here, need to revisit how it should work vs other app dirs above... just wanted to make sure I don't forget this spot
    # /System/Library/CoreServices/Finder.app # i.e. to find Movie dir, or Picture dir icons
    agimages /System/Library/CoreServices/ "$argv"

    # what other spots?

    # this direction would be useful if agimages also takes an optional search term to match the file name (in addition to the extension)
    # simple-icons repo
    #_agimages-dir ~/repos/github/simple-icons/simple-icons
end
