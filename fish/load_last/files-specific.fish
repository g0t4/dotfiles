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


## config
function _reload_config
    source ~/.config/fish/config.fish
end

function take
    mkdir -p $argv && cd $argv
end
