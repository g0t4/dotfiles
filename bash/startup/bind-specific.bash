# --no-space-after must be defined here, no way to port that b/c it's not part of fish's abbrs
abbr gcmsg='git commit -m "%"' --no-space-after --set-cursor

# TODO temporary until I port regex expansions

# declare -p abbrs  # sanity check
abbr declarep "declare -p % | bat -l bash" --set-cursor
abbr dp "declare -p % | bat -l bash" --set-cursor
abbr declareA "declare -A"
abbr dA "declare -A %"
abbr declarea "declare -a"
abbr da "declare -a %"
abbr declarei "declare -i"
abbr declarel "declare -l"
abbr declareu "declare -u"


# TODO mirror with sh.snippets from my nvim config...
# * would be cool to get a full blown snippet system in bash (and other shells)...
#  ea => echo "${placeholder1[@]}" # put cursor on placeholder1 slot
#     I could do this with cursor positioning like --set-cursor in fish abbrs
#     and I had an IMPL of that in zsh prior
#     jump positions too with Ctrl-J or similar (like nvim)
# shellcheck disable=SC2016 # expressions in single quotes don't expand, yup that's the point here!
abbr d@='"${%[@]}"' --position=anywhere --set-cursor
abbr d_array_length='${#%[@]}' --position=anywhere --set-cursor
abbr d*='"${%[*]}"' --position=anywhere --set-cursor
abbr dx='"${%}"' --position=anywhere --set-cursor
#
abbr d_default_value_if_unset='"${%:-default_value}"' --position=anywhere --set-cursor
abbr d_swap_if_set '"${%:+use_this_if_set}"' --position=anywhere --set-cursor
abbr d_assign_if_unset '"${%:=assign_this_if_unset}"' --position=anywhere --set-cursor
abbr d_error_if_unset '"${%:?error_message_if_unset}"' --position=anywhere --set-cursor
#
abbr dxu='${%}' --position=anywhere --set-cursor
abbr echo_variable='declare -p % | bat -l bash'         # arrays and scalars
abbr echo_array_element='echo _"${%[0]}"_' --set-cursor # array item, adds [0] as a convenience (could be a 2nd placeholder in a future snippets system)
abbr echo_array_length='echo ${#%[@]}' --set-cursor
#
# aliased, see which I prefer
abbr for_in_array='for item in "${%[@]}"; do echo $item; done' --set-cursor
abbr for_in_range='for i in "{1..10%}"; do echo $i; done' --set-cursor
abbr for_in_array_indicies='for i in "${!%[@]}"; do echo "${i} ${name[$i]}"; done' --set-cursor

abbr pIFS "echo -n \"\${IFS}\" | hexdump -C" # block word splitting, or it will split it's own characters :)
#
# print path one per line... two ways to do it
abbr pPATH '(IFS=:; for p in ${PATH}; do echo $p; done)'
#
# for fun... here's a diff variant:
# echo "${PATH//:/$'\n'}"
abbr pPATH "echo \"\${PATH//:/\$'\n'}\""
#  FYI remove outermost "" around expanded arg to echo... shows how IFS works and stopping it with quoting
#
# PRN add variant using printf?
# PRN add variant using read

_grvcp() {
    # see fish IMPL for latest version and notes
    first_remote=$(git remote | head -n 1)
    # FYI second half has the link visible, first half shows command used and copying it
    echo "git remote get-url $first_remote | pbcopy # $(git remote get-url "$first_remote")"
}

_expand_git_log() {
    if [[ "$1" =~ gl([0-9]+) ]]; then

        echo "git log -${BASH_REMATCH[1]}"
        return
    fi
    echo "git log"
}
abbr git_log_num --regex 'gl[0-9]*' --function _expand_git_log


# * trap
abbr trapl "trap -l"
abbr trapp "trap -p"
abbr trapP "trap -P"
