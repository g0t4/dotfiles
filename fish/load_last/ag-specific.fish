# *** ag color options ***
#   also uses ansi color codes like GREP
#   options:
#     --color-line-number # Default is 1;33. (fg: bold, yellow)
#     --color-match # Default is 30;43. (fg: default, bg: yellow)
#     --color-path # Default is 1;32. (fg: bold, green)
#

# ***! rg START
# - much faster, ~2x+
# - syntax highlighting of grep results
# - has config file
#
## notable differences
# -e foo -e bar => OR multiple search terms together
# - another config consideration... it uses rust regex format (not sure how all that differs from say PCRE2... can set pcre2 though)
# - `rg -g` => `rg --files | rg`
# - `rg -G foo bar` => `rg -g foo bar` # BUT, -g glob # is a glob not a regex
#    note: can always use `rg --files | rg foo | xargs rg bar` # to get back to regex

export RIPGREP_CONFIG_PATH=$WES_DOTFILES/.config/ripgrep/ripgreprc

# * basic file content search
abbr --set-cursor rgi 'rg -i "%"'
abbr --set-cursor agi 'rg -i "%"'
abbr --set-cursor rgh 'rg --hidden -i "%"'
abbr --set-cursor agh 'rg --hidden -i "%"'
abbr --set-cursor rgu 'rg -u "%"' # unrestricted
abbr --set-cursor agu 'rg -u "%"' # unrestricted
#
# * filename/path search (not contents)
abbr --set-cursor rgf 'rg --files'
abbr --set-cursor rgg 'rg --files | rg -i "%"' # * mirror `ag -g` (search filepaths not content)
abbr --set-cursor agg 'rg --files | rg -i "%"' # * mirror `ag -g` (search filepaths not content)
abbr --set-cursor rggi 'rg --files | rg -i "%"'
abbr --set-cursor rggh 'rg --files -h | rg -i "%"'
abbr --set-cursor aggh 'rg --files -h | rg -i "%"'
abbr --set-cursor rggu 'rg --files -u | rg -i "%"'
abbr --set-cursor aggu 'rg --files -u | rg -i "%"'

# * TODO filename + content search
abbr --set-cursor rg_G 'rg -g fileglob "%"' # use as a reminder for now

# * syntax highlighting of grep results
function delta_rg --wraps delta
    # add wrapper to keep command shorter, mostly so I can modify last search command without arrowing a million times back
    delta --features rg
end
#
# alternative... type `jd<SPACE>` on end of an rg command and it expands into the json delta for you!
abbr --command rg --position anywhere -- jd '--json | delta_rg'
# OR, have it start w/ json delta:
abbr --set-cursor rgjd 'rg --json "%" | delta_rg'
abbr --set-cursor rg_delta 'rg --json "%" | delta_rg' # reminder format (use command_what as a way to easily lookup new abbrs that I am trying to habituate)
#
abbr --set-cursor rgj 'rg --json "%"'
#
# *** troubleshooting
abbr rg_files 'rg --files' # * list files that would be searched
abbr rg_files_no_match 'rg --files-without-match' # ag -L
abbr rg_files_with_matches 'rg --files-with-matches' # ag -l
abbr rg_debug 'rg --debug'
abbr rg_trace 'rg --trace'
abbr rg_stats 'rg --stats'

abbr rgm 'rg --multiline --multiline-dotall' # dot as \n too

# ***rg (start to consider using this?)
abbr rgm 'rg --multiline --multiline-dotall' # dot as \n too

abbr --set-cursor rgd 'rg -d "%"'
abbr --set-cursor rgv 'rg -v "%"' # -v/--invert-match
abbr --set-cursor rgo 'rg -o "%"' # -o/--only-matching
abbr --set-cursor rgF 'rg -F "%"' # -F/--fixed-strings
abbr --set-cursor rgw 'rg -w "%"' # -F/--fixed-strings

# MOVED thes to ripgreprc file
# function rg
#     command rg --column --no-heading $argv
#     # TODO add smth for ag's --color-match
# end

# * --mmap                     (Search with memory maps when possible.)
#
### multiline search:
#  --multiline-dotall               (Make '.' match line terminators.)
# * -U  --multiline            (Enable searching across multiple lines.)
#
### config related?
# --no-config                       (Never read configuration files.)
# -j  --threads        (Set the approximate number of threads to use.)
# --hyperlink-format                         (Set the format of hyperlinks.)  - this is super cool, can include WSL distro on windows for clickable links into linux distros!
#
### ignores related:
# --no-ignore                               (Don't use ignore files.)
# --no-ignore-dot             (Don't use .ignore or .rgignore files.)
# --no-ignore-exclude              (Don't use local exclusion files.)
# --no-ignore-files              (Don't use --ignore-file arguments.)
# --no-ignore-global                 (Don't use global ignore files.)
# --no-ignore-vcs       (Don't use ignore files from source control.)
# --no-ignore-parent  (Don't use ignore files in parent directories.)
# --ignore-file                           (Specify additional ignore files.)
#
# --iglob                        (Include/exclude paths case insensitively.)
# -g  --glob                          (Include or exclude file paths.)
#
# -d  --max-depth                   (Descend at most NUM directories.)
#
# --passthru            (Print both matching and non-matching lines.)
#
# --sort                           (Sort results in ascending order.)
# --sortr                         (Sort results in descending order.)
# --sort-files              ((DEPRECATED) Sort results by file path.)
#
# --engine                              (Specify which regex engine to use.)
# -e  --regexp                              (A pattern to search for.)
# -P  --pcre2                                 (Enable PCRE2 matching.)
#
##
# --type-list
# --type-add                        (Add a new glob for a file type.)
# --type-clear                         (Clear globs for a file type.)
# -T  --type-not                  (Do not search files matching TYPE.)
# -t  --type                        (Only search files matching TYPE.)

# * rg/ag shared args:
# -i to ignore case
# --hidden (note ag also uses -h whereas rg does not)
# -u/--unrestricteda (not 100% same, still some filtering in rg)
# ag --[no-]group == rg --[no-]heading   # whether to filename on every line or to group matches per file and show name only above group, important for it to be per line for clickable "links" in iTerm2 semantic history
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

# ***! rg END

# FYI colors are defined by fish/zsh respectively in color-specific.{fish,zsh}
function ag
    command ag --nogroup --color-match "$__color_matching_text" --column $argv
    # --nogroup => disable grouping to show file/line per match to click to open in vscode (via iterm links)
end
# FYI can defer expand color variable so order of startup files is irrelevant

# # FYI uncomment to go back to ag
# abbr --set-cursor -- agi 'ag -i "%"'
# abbr --set-cursor -- agg 'ag -ig "%"'
# abbr --set-cursor -- agh 'ag --hidden -i "%"' # match hidden files, but not ignored files
# abbr --set-cursor -- agu 'ag --unrestricted -i "%"' # match hidden files + ignored files
# abbr --set-cursor -- aggh 'ag --hidden -ig "%"' # match hidden files, but not ignored files
# abbr --set-cursor -- aggu 'ag --unrestricted -ig "%"' # match hidden files + ignored files

# ignored files: .ignore, .gitignore, --ignore, etc
# hidden files: .config, .git (dotfiles/dirs)

# # FYI uncomment to go back to ag
# # * list file names (of matches)
# abbr agl 'ag -l' # print file name only, not matched content
# abbr agl 'ag -lu' # print file name only, not matched content
# abbr agl 'ag -l --hidden' # print file name only, not matched content
# abbr agL 'ag -L' # invert match (files w/o content matches)
# # * list files that are searched
# #    so you can see what is ignored vs not, what needs --unrestricted vs --hidden vs neither
# abbr agll 'ag -l # list files searched' # FYI thisis redundant but I wanna put it here so I don't forget its also in this group
# abbr aglu 'ag -lu # list files searched' #
# abbr aglh 'ag -l --hidden # list files searched, including hidden'
# # ? can I use -L somehow to list whats not searched? would be easier than diff below
function ag_files_searched
    ag -ll $argv | sort -u
end
function ag_files_searched_hidden
    ag -ll --hidden $argv | sort -u
end
function ag_files_searched_unrestricted
    ag -ll --unrestricted $argv | sort -u
end
function ag_files_searched_hidden_diff
    # show a diff of files searched with and without --hidden
    # see what files require --hidden to show up
    diff_two_commands 'ag -l | sort -h' 'ag -l --hidden | sort -h'
end
function ag_files_searched_unrestricted_diff
    # show a diff of files searched with and without --unrestricted
    # see what files require --unrestricted to show up
    diff_two_commands 'ag -l | sort -h' 'ag -l --unrestricted | sort -h'
end

# # FYI uncomment to go back to ag
# abbr agw 'ag --word-regexp' # match whole words
# abbr agz 'ag --search-zip' # search inside zip files (gz,xz only)
#
# # * multiline
# abbr --set-cursor agm 'ag "(?s)%"' # (?s) makes . match \n too
# #  example:
# #    ag -G fish "(?s)for[^(end)]*set[^(end)]*"
# #       here I was looking for for loops that use `set -`, first just `set`
# #       not sure this does what I want... it's hard to match across lines :) and not get crazy results
# #    find all for loops that set a variable (before they end)

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
