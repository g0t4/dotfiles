function icdiff
    # FYI I don't really like -H/--highlight as it often colors more than what is changed (icdiff help calls it "ugly")... so don't add -H here and force it globally... that can be tempting b/c the inversion pops better than font color... but then again the real issue I had was the default color map w/ yellow bold on yellow not standing out so I went with a color map mod instead:

    # inject color map changes (bold yellow doesn't stand out well versus my typical yellow default font color)
    # FYI default: --color-map='add:green_bold,change:yellow_bold,description:blue,meta:magenta,separator:blue,subtract:red_bold'
    command icdiff --color-map='add:green_bold,change:white_bold,description:blue,meta:magenta,separator:blue,subtract:red_bold' $argv

    # PRN wait until this causes a problem... but basically is there a case where I would want yellow_bold instead of white_bold? Probably not b/c if I have this modification for dotfiles then chances are I also have customized my terminal colors to make yellow font default and so white_bold will be a good choice then.
end

abbr ic icdiff
abbr icr "icdiff --recursive" # diff all files in two dirs
abbr icg git-icdiff
# configure git-icdiff via git config: git config --global icdiff.options '--line-numbers'

function _abbr_expand_diff_last_two_commands
    set last_two_commands (history | head -n 2)
    set command_a (string escape $last_two_commands[2]) # most recent on the right
    set command_b (string escape $last_two_commands[1]) # older on left
    echo diff_two_commands $command_a $command_b
end
abbr -a diff_last_two_commands --function _abbr_expand_diff_last_two_commands

# * append sort -h too
# FYI make sure original variant (above) is first completion result as I won't use this one as often
#    also, consider breaking the typical completion chain so I can tab to complete the above w/o then another tab to select it
# when output order might differ while content is the same
# i.e. `ls` in two diff dirs
function _abbr_expand_diff_last_two_commands_sorted
    set last_two_commands (history | head -n 2)

    # ! ensure command_a is a _single_ scalar value (not a multi-value array)
    # otherwise `string escape` operates on each value alone
    # which results in command_a turning into two arguments to diff_two_commands
    # when it should be one argument to diff_two_commands
    set -l command_a $last_two_commands[2]" | sort -h"
    # - same with command_b => one value
    set -l command_b $last_two_commands[1]" | sort -h"

    set command_a (string escape $command_a)
    set command_b (string escape $command_b)
    echo diff_two_commands $command_a $command_b
end
abbr -a diff_last_two_commands_sorted --function _abbr_expand_diff_last_two_commands_sorted

abbr -a diff_last_two_commands_stderr_too --function _abbr_expand_diff_last_two_commands_stderr_too
function _abbr_expand_diff_last_two_commands_stderr_too
    set last_two_commands (history | head -n 2)
    set -l command_a $last_two_commands[2]" 2>&1"
    set -l command_b $last_two_commands[1]" 2>&1"
    set command_a (string escape $command_a)
    set command_b (string escape $command_b)
    echo diff_two_commands $command_a $command_b
end

function diff_two_commands --wraps icdiff
    # usage:
    #   diff_two_commands "ls -al" "ls -al | sort -h"
    #   don't really need -- support here b/c there are only ever two args (commands to diff) and so any other options are clearly for icdiff (thus far)

    set command_a $argv[1]
    set command_b $argv[2]
    set icdiff_argv $argv[3..]

    # * replace { and } with _
    #   !!! b/c icdiff's -L uses {} for interpolation of {path} and {basename}
    set label_a (string replace --regex --all -- '[\{\}]' '_' $command_a)
    set label_b (string replace --regex --all -- '[\{\}]' '_' $command_b)

    icdiff $icdiff_argv \
        -L $label_a (eval $command_a | psub) \
        -L $label_b (eval $command_b | psub)
end

function test_diff_expansions_when_open_new_shell
    history append "echo '1 2 3 4' | awk '{ print \$3 }'"
    history append "echo '1 2 6' | awk '{ print \$3 }'"
    _abbr_expand_diff_last_two_commands $command_a $command_b
    _abbr_expand_diff_last_two_commands_sorted $command_a $command_b
    _abbr_expand_diff_last_two_commands_stderr_too $command_a $command_b
end
# uncomment => open new shell to test abbrs:
test_diff_expansions_when_open_new_shell

function test_diff_two_commands_when_open_new_shell
    #
    # how to test with {}
    #  run both of these commands:
    #
    #    echo '1 2 3 4' | awk '{ print $3 }'
    #    echo '1 2 6' | awk '{ print $3 }'
    #
    set command_a (history --prefix "echo '1 2 3" | head -1)
    set command_b (history --prefix "echo '1 2 6" | head -1)
    #
    # FYI alternative => setup iterm2 test harness that types for me on a hotkey (wes.py)
    #

    diff_two_commands $command_a $command_b
end
# *** DO NOT manually invoke two commands and then the abbr just to run test diff_two_commands!!
# *** uncomment and open new shell:
test_diff_two_commands_when_open_new_shell

function diff_command_args --wraps icdiff
    # FYI to unambiguously pass icdiff options too, use --
    #   diff_command_args [icdiff options] -- [diff args...]
    #   diff_command_args -H -- "ls -al" -t

    # argv[1] is the command to run
    # $argv[2..-1] remainder of args are the diff args to pass (with and without)
    #    if passing a pipe make sure to quote it else will not be an arg to this function!
    #    e.g. diff_command_args "echo foo\nbar" "--line-numbers" "| grep foo"
    # ALSO, if there is no diff (and no error) then its very likely not this code but the output is literally the same :)... sometimes when testing you don't always get what you expect... run commands separately to verify if they are the same

    # *** cannot do like diff_two_commands above b/c there are more 2+ args possible to the diff here and cannot differentiate which would be for icdiff vs comparison so just allowing the two special icdiff options
    # FYI argparse strips specified options (i.e. -H/--highlight) AND strips -- (if present)...  so if you remove this then you will no longer be able to use --
    argparse --ignore-unknown H/highlight W/whole-file -- $argv
    # --ignore-unknown is necessary to avoid parsing args when "--" is not used

    icdiff $_flag_highlight $_flag_whole_file \
        -L "'$argv[1]'" (eval $argv[1] | psub) \
        -L "'$argv[1] $argv[2..-1]'" (eval $argv[1] $argv[2..-1] | psub)
end

function _current_command_or_previous

    set user_input (commandline -b)
    if test -z $user_input
        set user_input (history | head -n 1)
        # PRN use $history (does it have items not added to history file, IIAC?)
    end
    echo $user_input

end

# *** bindings to replace current command with a diff_ helper command ***

function _convert_current_command_to_diff_command_args
    # use to compare same command w/ and w/o a set of args
    set user_input (_current_command_or_previous)
    commandline --replace "diff_command_args '$user_input' "
end

bind_both_modes_default_and_insert f5 _convert_current_command_to_diff_command_args
bind_both_modes_default_and_insert ctrl-f5 _convert_current_command_to_diff_command_args # ctrl+F5 (streamdeck button => hotkey action)

function _convert_current_command_to_diff_two_commands
    # use to compare w/ add and remove from current command
    set user_input (_current_command_or_previous)
    commandline --replace "diff_two_commands '$user_input' '$user_input' "
end
bind_both_modes_default_and_insert f6 _convert_current_command_to_diff_two_commands
bind_both_modes_default_and_insert ctrl-f6 _convert_current_command_to_diff_two_commands # ctrl+F6 (streamdeck button => hotkey action)
# see which binding I prefer (F6 or streamdeck)
#    yes I know I can reuse f6 for stremadeck too but I think I will get rid of that one and use it elsewhere so that is why I have both bound here for now

# *** some bind key combos ***
#
#   read "terminal input sequences": https://en.wikipedia.org/wiki/ANSI_escape_code#Terminal_input_sequences
#
#   examples (see wikipeida page for other lookups):
#       F5          [15~
#       F6          [17~
#       F7          [18~
#       shift + F7  [18;2~
#       ctrl + F7   [18;5~   (see above where I use this, for proper escaping ])
#       alt + F7    [18;9~
#   modifiers (last #):
#       shift    ;2~
#       ctrl     ;5~
#       alt      ;9~
#
#   exceptions (examples, there are many):
#       shift+F1  [1;2P
#       shift+F2  [1;2Q
#       shift+F3  [1;2R
#       shift+F4  [1;2S
#         # very likely some of this has to do with how iterm maps bindings (it has choices for this and I should avoid changing that again without clearly knowing what I am doing :)...
#

#
# FYI if want these then add back (maybe new file)... I never really have used these in zsh so I don't think they're pivotal here though I could do icdiff (!-2) (!-2) typed out and it would expand out to work in that one off case :)... still more work than other ways
# # expand !!
# # based on https://fishshell.com/docs/current/relnotes.html#fish-3-6-0-released-january-7-2023
# function last_history_item
#     echo $history[1]
# end
# abbr -a !! --position=anywhere --function last_history_item
# # crap I need these to work as aliases :) or funcs... not as abbreviation
# #   TODO rewrite as func only with pattern matching of func name (that's a thing right, parameterized func names? - not func params)
# # expand !-X
# function expand_history_item_X
#     set -l history_num (string replace '!-' '' $argv)
#     echo $history[$history_num]
# end
# abbr --add bangbang --regex '\!\-\d+' --position=anywhere --function expand_history_item_X
