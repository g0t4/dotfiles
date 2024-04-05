
abbr ic "icdiff -H"
abbr icr "icdiff --recursive" # diff all files in two dirs
abbr icg git-icdiff
# configure git-icdiff via git config: git config --global icdiff.options '--line-numbers'

# For example:
# > echo foo\nbar
# > echo bar
# > diff_last_two_commands<SPACE> # expands to:
# > icdiff -L "echo foo\nbar" (echo foo\nbar | psub) -L "echo bar" (echo bar | psub)
function expand_diff_last_two_commands
    # TODO validate this works for more complex commands
    set last_two_commands (history | head -n 2)
    set -l command_a $last_two_commands[2]
    set -l command_b $last_two_commands[1]
    # set command_a "echo foo\nbar"
    # set command_b "echo bar"
    echo icdiff -L "'$command_a'" "($command_a | psub)" -L "'$command_b'" "($command_b | psub)"
    # https://fishshell.com/docs/current/cmds/psub.html
end
# abbr -a diff_last_two_commands --function expand_diff_last_two_commands
function expand_diff_last_two_commands_with_diff_two_commands
    set last_two_commands (history | head -n 2)
    set -l command_a $last_two_commands[2]
    set -l command_b $last_two_commands[1]
    echo diff_two_commands "$command_a" "$command_b"
end
abbr -a diff_last_two_commands --function expand_diff_last_two_commands_with_diff_two_commands


function diff_two_commands
    # usage:
    #   diff_two_commands "ls -al" "ls -al | sort -h"

    icdiff \
        -L "'$argv[1]'" (eval $argv[1] | psub) \
        -L "'$argv[2]'" (eval $argv[2] | psub)
end

function diff_command_args
    # argv[1] is the command to run
    # $argv[2..-1] remainder of args are the diff args to pass (with and without)
    #    if passing a pipe make sure to quote it else will not be an arg to this function!
    #    e.g. diff_command_args "echo foo\nbar" "--line-numbers" "| grep foo"
    # ALSO, if there is no diff (and no error) then its very likely not this code but the output is literally the same :)... sometimes when testing you don't always get what you expect... run commands separately to verify if they are the same

    icdiff \
        -L "'$argv[1]'" (eval $argv[1] | psub) \
        -L "'$argv[1] $argv[2..-1]'" (eval $argv[1] $argv[2..-1] | psub)

end

# FYI if want these then add back (maybe new file)... I never really have used these in zsh so I don't think they're pivotal here though I could do icdiff (!-2) (!-2) typed out and it would expand out to work in that one off case :)... still more work than other ways
# # expand !!
# # based on https://fishshell.com/docs/current/relnotes.html#fish-3-6-0-released-january-7-2023
# function last_history_item
#     echo $history[1]
# end
# abbr -a !! --position anywhere --function last_history_item
# # crap I need these to work as aliases :) or funcs... not as abbreviation
# #   TODO rewrite as func only with pattern matching of func name (that's a thing right, parameterized func names? - not func params)
# # expand !-X
# function expand_history_item_X
#     set -l history_num (string replace '!-' '' $argv)
#     echo $history[$history_num]
# end
# abbr --add bangbang --regex '\!\-\d+' --position anywhere --function expand_history_item_X
