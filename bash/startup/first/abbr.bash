declare -A abbrs=(
    [gst]="git status"
    [gdlc]="git log --patch HEAD~1..HEAD"
)
expand_abbr() {
    local cmd=$READLINE_LINE
    local expanded="${abbrs[$cmd]}"
    if [[ "$expanded" != "" ]]; then
        # expand and add space:
        READLINE_LINE="${expanded} " # $'\n'  # this inserts new line like multiline! close but not yet
    else
        # otherwise just add space:
        READLINE_LINE="${cmd} "
    fi
    READLINE_POINT=${#READLINE_LINE} # then, move cursor to end too
    # bind has an accept-line! I wish I could trigger it... why can't I?!
}
bind -x '" ":expand_abbr " "' # on space works!

command_not_found_handle() {
    # TODO would be nice to use bind -x to expand the abbr TOO and then have that submit the command with bind's `accept-line`...
    # just haven't figured out how to trigger that yet!
    # inserting $'\n' literally adds a new line

    # TODO capture existing command_not_found_handle func and call it too?
    local expanded="${abbrs[$1]}"
    if [[ "$expanded" != "" ]]; then
        eval "$expanded"
    fi
}

abbr() {
    # PRN handle options (if any) when I add abbrs that use them
    # PRN do I need to slice all remaining args?
    abbrs["${1}"]="${2}"
}

abbr dils "docker image ls"
abbr dcls "docker container ls"
