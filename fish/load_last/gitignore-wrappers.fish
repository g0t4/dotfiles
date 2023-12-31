function gi
    zsh -ic "gi $argv"
end

# --wraps => use completions from gi
function gic --wraps gi
    zsh -ic "gic $argv"
end

function gia --wraps gi
    zsh -ic "gia $argv"
end

complete -c gi --no-files

function _gitignoreio_get_command_list
    # uncomment to see this is run at completion time:
    #   echo querying gitignore.io commands
    zsh -ic "_gitignoreio_get_command_list $argv"
end
# _gitignore_git_command_list won't be run until completion time
complete -c gi -a '(_gitignoreio_get_command_list)'
# complete -c foo # shows completions for foo
