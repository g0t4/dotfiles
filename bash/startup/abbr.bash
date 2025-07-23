declare -A abbrs=(
    [gst]="git status"
    [gdlc]="git log --patch HEAD~1..HEAD"
)
expand_abbr() {
    local cmd=$READLINE_LINE
    local expanded="${abbrs[$cmd]}"
    if [[ "$expanded" != "" ]]; then
        # expand and add space:
        READLINE_LINE="${expanded} "
    else
        # otherwise just add space:
        READLINE_LINE="${cmd} "
    fi
    READLINE_POINT=${#READLINE_LINE} # then, move cursor to end too
}
# bind -x '"\C-a":expand_abbr'
bind -x '" ":expand_abbr' # on space works!
# TODO intercept ENTER too and expand before submit command

abbr() {
    # PRN handle options (if any) when I add abbrs that use them
    # PRN do I need to slice all remaining args?
    abbrs["${1}"]="${2}"
}

abbr dils "docker image ls"
abbr dcls "docker container ls"
