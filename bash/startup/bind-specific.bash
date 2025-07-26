# --no-space-after must be defined here, no way to port that b/c it's not part of fish's abbrs
abbr gcmsg='git commit -m "%"' --no-space-after --set-cursor

# TODO temporary until I port regex expansions
abbr gl10 "git log -10"

# declare -p abbrs  # sanity check
abbr declarep "declare -p % | bat -l bash" --set-cursor

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
abbr dxu='${%}' --position=anywhere --set-cursor
abbr echo_array_length='echo ${#%[@]}' --set-cursor
abbr echo_scalar='echo _"${%}"_' --set-cursor
abbr echo_array='declare -p % | bat -l bash'
abbr echo_array_element='echo _"${%[0]}"_' --set-cursor # array item, adds [0] as a convenience
#
# aliased, see which I prefer
abbr for_in_array='for item in "${%[@]}"; do echo $item; done' --set-cursor
abbr for_in_range='for i in "{1..10%}"; do echo $i; done' --set-cursor
abbr for_in_array_indicies='for i in "${!%[@]}"; do echo "${i} ${name[$i]}"; done' --set-cursor

abbr pIFS "echo -n \"\${IFS}\" | hexdump -C" # block word splitting, or it will split it's own characters :)

_grvcp() {
    # see fish IMPL for latest version and notes
    first_remote=$(git remote | head -n 1)
    # FYI second half has the link visible, first half shows command used and copying it
    echo "git remote get-url $first_remote | pbcopy # $(git remote get-url "$first_remote")"
}
