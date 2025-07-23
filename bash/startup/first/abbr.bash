declare -A abbrs=(
    [gst]="git status"
    [gdlc]="git log --patch HEAD~1..HEAD"
)
expand_abbr() {
    local cmd=$READLINE_LINE
    local expanded=""
    if [[ "$cmd" != "" ]]; then
        expanded="${abbrs[$cmd]}"
    fi
    local add_char=" "
    if [[ "$expanded" != "" ]]; then
        # expand and add space:
        READLINE_LINE="${expanded}${add_char}"
    else
        # otherwise just add space:
        READLINE_LINE="${cmd}${add_char}"
    fi
    READLINE_POINT=${#READLINE_LINE} # then, move cursor to end too
}
bind -x '" ": expand_abbr " "'

# hack - composite keymap to invoke both funcs
bind -x '"\C-]": expand_abbr "enter"'
bind '"\C-t": accept-line'
bind '"\C-m": "\C-]\C-t"'

command_not_found_handle() {
    # TODO would be nice to use bind -x to expand the abbr TOO and then have that submit the command with bind's `accept-line`...
    # just haven't figured out how to trigger that yet!
    # inserting $'\n' literally adds a new line

    # TODO capture existing command_not_found_handle func and call it too?
    local expanded="${abbrs[$1]}"
    if [[ "$expanded" != "" ]]; then
        eval "$expanded"
    else
        echo "command not found"
        return 127
    fi
}

abbr() {
    # PRN handle options (if any) when I add abbrs that use them
    # PRN do I need to slice all remaining args?
    abbrs["${1}"]="${2}"
}

abbr dils "docker image ls"
abbr dcls "docker container ls"
