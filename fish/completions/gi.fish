
# uncomment to see when this file is loaded:
# echo "loading gi.fish"

complete -c gi --no-files

function _gitignoreio_get_command_list
    # uncomment to see this is run at completion time:
    #   echo querying gitignore.io commands
    # - thus, I could inline this into gitignore commands script
    # - but I find it easier to define it all here

    zsh -ic "_gitignoreio_get_command_list $argv"
end

# _gitignore_git_command_list won't be run until completion time
complete -c gi -a '(_gitignoreio_get_command_list)'

# complete -c foo # shows completions for foo
