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
