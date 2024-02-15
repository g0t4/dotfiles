# # ... etc aliases


# # PRN switch to loop for alias? I shouldn't have one for zsh specific variant either :)... this is much more readable (PRN turn into abbreviation? but then it would expand :( )
# alias ...="cd ../.."
# alias ....="cd ../../.."
# alias .....="cd ../../../.."
# alias ......="cd ../../../../.."
# alias .......="cd ../../../../../.."
# alias ........="cd ../../../../../../.."
# alias .........="cd ../../../../../../../.."
# alias ..........="cd ../../../../../../../../.."
# alias ...........="cd ../../../../../../../../../.."

# this was in release notes for 3.6.0! regex just added (among other changes)
#    https://fishshell.com/docs/3.6/relnotes.html
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end

abbr --add dotdot --regex '^\.\.+$' --function multicd

# cd-
abbr --add cd- 'cd -'

## config
function _reload_config
    source ~/.config/fish/config.fish
end
function _update_dotfiles
    if test ! -d $WES_DOTFILES
        echo "dotfiles not found..."
        return
    end
    cd $WES_DOTFILES
    git pull
end

function take
    mkdir -p $argv && cd $argv
end



## cd_dir_of helpers
#
# zsh's =cmd expansion as fish abbreviation!
#   =fish => /opt/homebrew/bin/fish
function expand_zsh_equals
    set -l cmd (string replace --regex '^=' '' $argv)
    type --path $cmd
end
abbr --add zsh_equals --regex '=[^\b]+' --function expand_zsh_equals

function cd_dir_of_command
    cd_dir_of_path (type --path $argv) # ~ zsh's =foo
end
ealias cdc="cd_dir_of_command"

function cd_dir_of_path
    set -l _cd_path $argv
    argparse --min 1 -- $argv or return 1

    if test ! -e $_cd_path
        echo "$_cd_path not found"
        return
    end

    # resolve symlinks (-f => recursively)
    if test -L $_cd_path
        echo -e "symlink:\n   $_cd_path =>"
        set _cd_path $(readlink -f $_cd_path)
        # PRN use `path resolve $_cd_path` instead (fish only)
    end

    if test -d $_cd_path
        # dir
        cd $_cd_path
    else
        # file
        cd (dirname $_cd_path)
    end

    log_ --apple_white "cd $(pwd)"
end
ealias cdd="cd_dir_of_path"

# if batcat exists map to bat
if type batcat &>/dev/null
    # ubuntu
    alias bat=batcat
end

### DISK USAGE ###
# only expand du, don't also alias
abbr du 'du -hd1 | sort -h --reverse' # sort by size (makes sense only for current dir1) => most of the time this is what I want to do so just use this for `du`
#  FYI I could add psh => '| sort -hr' global alias (expands anywhere)?
# retire: ealias du='du -h'  # tree command doesn't show size of dirs (unless showing entire hierarchy so not -L 2 for example, so stick with du command)
ealias dua='du -ha' # show all files (FYI cannot use -a with -d1)
ealias duh='du -h' # likely not needed, old du defaults before sort default
#
# show only N levels deep
#   du1 => du -hd 1
abbr --add _duX --regex 'du\d+' --function duX
function duX
    string replace --regex '^du' 'du -hd' $argv
end
#
ealias df='command df -h' # use command to avoid infinite recursion
# Mac HD: (if fails try df -h and update this alias to be be more general)
ealias dfm='df -h /System/Volumes/Data'

## loop helpers
ealias forr='for i in (seq 1 3)
    # PRN add forr30 abbr => for i in (seq 1 30); echo $i; end
    echo $i
end
' # FYI if end' on last line that triggers parse failure (stating end can't take args) so I put ' on next line

##### find helpers #####
# WIP - new ideas to consider (added when trying to find ~/Library/Application\ Support/*elgato* dirs for streamdeck config)
# find directories by name
abbr --add findd --set-cursor=! 'find . -type d -iname "*!*"'
abbr --add finddr --set-cursor=! 'find . -type d -iregex ".*!.*"' # another idea to consider
# IDEAs: tree command for dirs? or exa?


###### ls/exa/eza/lsd/etc ######
# PRN port over zsh mods for ls to use eza (though I am happy with fish's ls currently)

###### tree ######
set _tree_exa 'eza --tree --group-directories-first --ignore-glob "node_modules|bower_components|.git" --color-scale=all --icons --git-repos'
set _treed "tree --only-dirs"

alias tree="$_tree_exa"
ealias treed="$_treed"

set _treeal "tree --all --long --group --sort size"
ealias treev="$_treeal"

# interchangable:
ealias treedv="$_treeal --only-dirs"
ealias treevd="$_treeal --only-dirs"

# treeX => tree -L X
abbr --add _treeX --regex 'tree\d+' --function treeX
function treeX
    string replace --regex '^tree' 'tree -L' $argv
end
# treedX => treed -L X 
abbr --add _treedX --regex 'treed\d+' --function treedX
function treedX
    string replace --regex '^treed' 'treed -L' $argv
end
# treevX => treev -L X
abbr --add _treevX --regex 'treev\d+' --function treevX
function treevX
    string replace --regex '^treev' 'treev -L' $argv
end

ealias treeify="as-tree" # PRN do I ever use this?
