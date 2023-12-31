
# uncomment to see when this file is loaded:
# echo "loading gi.fish"

complete -c gi --no-files

function _gitignoreio_get_command_list
    # uncomment to see this is run at completion time:
    #   echo querying gitignore.io commands
    # - thus, I could inline this into gitignore commands script
    # - but I find it easier to define it all here

    curl -sfL https://www.gitignore.io/api/list | tr "," "\n"
    # results are both comma and newline delimited:
    # - fish won't split on both command and \n (only \n if both)
    # - thus, replace comma => \n so they're consistently delimited

    # after first run, completions are effectively cached for the session (one api call per shell instance)
end

# _gitignore_git_command_list won't be run until completion time
complete -c gi -a '(_gitignoreio_get_command_list)'

# complete -c foo # shows completions for foo (if autoloaded must first trigger completion, i.e. foo<TAB> before they will be listed)
# docs:
#   (man complete) https://fishshell.com/docs/current/cmds/complete.html
#   (overview) https://fishshell.com/docs/current/completions.html
