

# --no-space-after must be defined here, no way to port that b/c it's not part of fish's abbrs
abbr gcmsg='git commit -m "%"' --no-space-after --set-cursor

# TODO temporary until I port regex expansions
abbr gl10 "git log -10"

# declare -p abbrs  # sanity check
abbr declarep "declare -p"
# would be cool to get a full blown snippet system in bash (and other shells)...
#  ea => echo "${placeholder1[@]}" # put cursor on placeholder1 slot
#     I could do this with cursor positioning like --set-cursor in fish abbrs
#     and I had an IMPL of that in zsh prior
# shellcheck disable=SC2016 # expressions in single quotes don't expand, yup that's the point here!
abbr ea='echo "${%[@]}"' -g --set-cursor

abbr pIFS "echo -n \"\${IFS}\" | hexdump -C" # block word splitting, or it will split it's own characters :)

