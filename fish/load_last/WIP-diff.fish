#
# *** FYI due to command substitution and history expansion differences, this is currently only applicable to fish (not zsh)

# icdiff
# PRN export ICDIFF_OPTIONS="--highlight" # FYI highlight is not an automatically wise idea to use, it loses some of value of icdiff (I do like it for ffmpeg and mediainfo output that is often very similar except for a few fields, so then the background color stands out much more than text color alone... might indicate I shouldn't use yellow for white too ;)  )
ealias ic="icdiff -H"
ealias icr="icdiff --recursive" # diff all files in two dirs
ealias icg="git-icdiff"
# configure git-icdiff via git config: git config --global icdiff.options '--line-numbers'
# thanks to expanding alises + zsh param expansion => it's clear what will happen (ie commands will be re-run)... essentially saves copy/paste previous two commands into icdiff <(cmd1) <(cmd2) format"
# - i.e. `echo foo` then `echo bar` results in: `icdiff <(echo foo) <(echo foobar)`
function diff_last_two_commands
    # PRN diff_last_two_rerun => if need to re-run comparison (save two cmds to local vars in this file and can re-run then!) => or rediff the tmp files only? why re-run if that isn't whats needed (ie just wanted to clear screen and run in cleared screen... meh just figure this out as needed)
    set tmp_a (mktemp)
    set tmp_b (mktemp)

    set last_two_commands (history | head -n 2)
    set -l command_a $last_two_commands[2]
    set -l command_b $last_two_commands[1]
    eval $command_a >$tmp_a
    eval $command_b >$tmp_b

    icdiff -L $command_a $tmp_a -L $command_b $tmp_b
    # PRN save icdiff to eval for re-run?

    rm $tmp_a $tmp_b

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
