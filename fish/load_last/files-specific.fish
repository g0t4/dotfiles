
# *** ls
# still not using exa/eza (not worth hassle, esp b/c fish builtin ls/la colors work well enough)
abbr lat "ls -alt"

# this was in release notes for 3.6.0! regex just added (among other changes)
#    https://fishshell.com/docs/3.6/relnotes.html
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end

abbr --add dotdot --regex '^\.\.+$' --function multicd

# cd-
abbr --add cd- 'cd -'

## *** fish related

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

function _update_os_lazy

    if command -q apt
        sudo apt update
        sudo apt dist-upgrade -y
        sudo apt autoremove -y
        sudo apt clean
    end

end

function _update_completion
    # PRN add more completions (helm, kubectl, etc)

    mkdir -p ~/.config/fish/completions/

    echo "updating completions in ~/.config/fish/completions/"

    command -q minikube; and minikube completion fish >~/.config/fish/completions/minikube.fish
    command -q kubectl; and kubectl completion fish >~/.config/fish/completions/kubectl.fish
    command -q helm; and helm completion fish >~/.config/fish/completions/helm.fish

    command -q docker; and docker completion fish >~/.config/fish/completions/docker.fish
    # FYI fish shell only, generated completions are superior to DDfM bundled completions

    # why? one reason is I can install beta releases of these tools and uninstall brew package and not lose out on completions

end

function _recording

    # PRN if calling repeatedly (ie on spal activate) causes problems => return if already in recording mode?

    _disable_fish_suggestions

    # ? use diff history file i.e. for ctrl+R history pager search
    # set -U fish_history recording # ~/.local/share/fish/recording_history

    # TODO disable showing return code failures in prompt? wait to see how much of a hassle this is when editing some new videos

    # FYI - I added Keyboard Maestro macros to:
    #   on screenpal (launch or activate) =>
    #       /opt/homebrew/bin/fish -c "_recording" 2>&1
    #       PRN on activate too?
    #       FYI can take a second or two to apply to all windows
    #   on screenpal quits =>
    #       /opt/homebrew/bin/fish -c "_not_recording" 2>&1
    # ?? PRN quicktime too?

end

function _not_recording
    _enable_fish_suggestions
    # set -U fish_history default # revert to ~/.local/share/fish/fish_history
end

function _disable_fish_suggestions
    #https://fishshell.com/docs/current/language.html#envvar-fish_autosuggestion_enabled
    set -U fish_autosuggestion_enabled 0
    # -U => universal applies to all windows (can be slight lag to apply to all windows, but most of the time its nearly immediate)
end

function _enable_fish_suggestions
    set -U fish_autosuggestion_enabled 1
end




## dirs
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
abbr cdc cd_dir_of_command

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
abbr cdd cd_dir_of_path


# *** bat ***
# if batcat exists map to bat
if command -q batcat # -q => w/o output
    # ubuntu
    function bat
        batcat $argv
    end
end
abbr cat bat # do not alias, only expand (abbr), else get failure trying to use cat.... TLDR as I type cat replace it with bat
abbr bath 'bat --style=header' # == header-filename (i.e. for multi files show names)
abbr batf 'bat --style=full'


### DISK USAGE ###
# only expand du, don't also alias
abbr du 'du -hd1 | sort -h --reverse' # sort by size (makes sense only for current dir1) => most of the time this is what I want to do so just use this for `du`
#  FYI I could add psh => '| sort -hr' global alias (expands anywhere)?
# retire: abbr du 'du -h'  # tree command doesn't show size of dirs (unless showing entire hierarchy so not -L 2 for example, so stick with du command)
abbr dua 'du -ha' # show all files (FYI cannot use -a with -d1)
abbr duh 'du -h' # likely not needed, old du defaults before sort default
#
# show only N levels deep
#   du1 => du -hd 1
abbr --add _duX --regex 'du\d+' --function duX
function duX
    string replace --regex '^du' 'du -hd' $argv
end
#
abbr df 'command df -h' # use command to avoid infinite recursion
# Mac HD: (if fails try df -h and update this alias to be be more general)
abbr dfm 'df -h /System/Volumes/Data'

## loop helpers
abbr forr 'for i in (seq 1 3)
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
set _treed "tree --only-dirs"

function tree
    eza --tree --group-directories-first --ignore-glob "node_modules|bower_components|.git" --color-scale=all --icons --git-repos $argv
end

abbr treed "$_treed"

set _treeal "tree --all --long --group --sort size"
abbr treev "$_treeal"

# interchangable:
abbr treedv "$_treeal --only-dirs"
abbr treevd "$_treeal --only-dirs"

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

abbr treeify as-tree # PRN do I ever use this?
