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
abbr d@#='${#%[@]}' --position=anywhere --set-cursor
abbr d*='"${%[*]}"' --position=anywhere --set-cursor
abbr dx='"${%}"' --position=anywhere --set-cursor
abbr dxu='${%}' --position=anywhere --set-cursor
abbr ed*='declare -p'
abbr ed@#='echo ${#%[@]}' --set-cursor
abbr edi='echo _"${%[0]}"_' --set-cursor # array item, adds [0] as a convenience
abbr edx='echo _"${%}"_' --set-cursor
abbr edxu='echo _${%}_' --set-cursor
abbr f@='for item in "${%[@]}"; do echo $item; done' --set-cursor

abbr pIFS "echo -n \"\${IFS}\" | hexdump -C" # block word splitting, or it will split it's own characters :)

# BTW this doesn't use the commandline :)... that's fine, good first test
_grvcp() {
    # see fish IMPL for latest version and notes
    first_remote=$(git remote | head -n 1)
    # FYI second half has the link visible, first half shows command used and copying it
    echo "git remote get-url $first_remote | pbcopy # $(git remote get-url "$first_remote")"
}
# TODO once this is working, just let this copy over from fish shell's abbr? or should I redefine these abbrs manually and always skip them in the migrate script?
abbr -a --function _grvcp -- grvcp
