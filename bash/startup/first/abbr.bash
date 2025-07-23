declare -A abbrs=(
    [gst]="git status"
    [gdlc]="git log --patch HEAD~1..HEAD"
)
expand_abbr() {
    local key="$1"
    local cmd=$READLINE_LINE
    local expanded=""
    if [[ "$cmd" != "" ]]; then
        expanded="${abbrs[$cmd]}"
    fi
    local add_char=" "
    if [[ "$key" == "enter" ]]; then
        add_char=""
    fi
    if [[ "$expanded" != "" ]]; then
        # expand and add space:
        READLINE_LINE="${expanded}${add_char}"
    else
        # otherwise just add space:
        READLINE_LINE="${cmd}${add_char}"
    fi
    READLINE_POINT=${#READLINE_LINE} # then, move cursor to end too
}
# * expand on <Space>
bind -x '" ": expand_abbr " "'

# * expand on <Return>
# hack - composite keymap to invoke both funcs
#  FYI if issues quoting this.. just inline the keys and don't use variables :)
expand_hack='\C-x\C-['
acceptline_hack='\C-x\C-]'
bind -x "\"$expand_hack\": expand_abbr enter"
bind "\"$acceptline_hack\": accept-line"
bind "\"\C-m\": \"$expand_hack$acceptline_hack\""

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

abbr gp "git push"
abbr gap "git add --patch"
abbr gcmsg "git commit -m '" # PRN could add the '' and cursor between... like zsh impl
abbr gdc "git diff --cached --color-words"

abbr n nvim

abbr dils "docker image ls"
abbr dcls "docker container ls"
