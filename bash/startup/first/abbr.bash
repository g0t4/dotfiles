declare -A abbrs=()
declare -A abbrs_no_space_after=()
expand_abbr() {
    local key="$1"
    local cmd=$READLINE_LINE
    # TODO take cursor position and get word before, including offsets, so I can replace anywhere in commandline...
    #    then when I have that, I can add a global (-g) flag like I have in ealias in zsh
    local expanded=""
    if [[ "$cmd" != "" ]]; then
        expanded="${abbrs[$cmd]}"
    fi
    local add_char=" "
    if [[ "$key" == "enter" ]]; then
        add_char=""
    fi
    if [[ "${abbrs_no_space_after["$cmd"]}" ]]; then
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
expand_hack='\C-x\C-['
# acceptline_hack='\C-x\C-]'
acceptline_hack='\C-j' # OOB accept-line
bind -x "\"$expand_hack\": expand_abbr enter"
bind "\"$acceptline_hack\": accept-line"          # bind -p # lists readline actions
bind "\"\C-m\": \"$expand_hack$acceptline_hack\"" # bind -s # lists macro actions

command_not_found_handle() {
    # TODO capture existing command_not_found_handle func and call it too?
    # FYI type out `gst --short` and use Ctrl-j to submit and test this w/o expanding:
    exec_abbr "$@"
}

exec_abbr() {
    # usage:
    #   exec_abbr gst # pass abbr name
    #   exec_abbr gst --short # can pass args too!
    name="$1"
    local expanded="${abbrs[$name]}"
    if [[ "$expanded" != "" ]]; then
        shift # pop first arg which is expanded
        $expanded "$@"
    else
        echo "abbr not found: '$name'"
        return 127
    fi
}

abbr() {
    # PRN handle options (if any) when I add abbrs that use them
    # PRN do I need to slice all remaining args?
    abbrs["${1}"]="${2}"

    # define stub function so I get tab completion of abbr names
    #  i.e. g<TAB> includes my g* abbrs
    eval "function ${1} { true; }"
}

ealias() {
    # compat layer, also this is where I'll accept --NoSpaceAfter
    # FORMAT
    #   key=value
    #   key=value --NoSpaceAfter
    #   PRN other options

    local key="${1%=*}"
    local value="${1#*=}"
    abbr "$key" "$value"

    # FYI check with:
    #     declare -p abbrs_no_space_after

    if indexed_array_contains "--NoSpaceAfter" "${@}"; then
        abbrs_no_space_after["$key"]=yes
    fi
}

abbr gst "git status"
abbr gdlc "git log --patch HEAD~1..HEAD"

ealias gcmsg='git commit -m "' --NoSpaceAfter
ealias gp="git push"

abbr gap "git add --patch"
abbr gdc "git diff --cached --color-words"
abbr gl "git log"
abbr gl10 "git log -10"

abbr n nvim

abbr dils "docker image ls"
abbr dcls "docker container ls"

# declare -p abbrs  # sanity check
abbr declarep "declare -p"
# would be cool to get a full blown snippet system in bash (and other shells)...
#  ea => echo "${placeholder1[@]}" # put cursor on placeholder1 slot
#     I could do this with cursor positioning like --set-cursor in fish abbrs
#     and I had an IMPL of that in zsh prior
# shellcheck disable=SC2016 # expressions in single quotes don't expand, yup that's the point here!
abbr ea 'echo "${name[@]}"'

abbr pIFS "echo -n \"\${IFS}\" | hexdump -C" # block word splitting, or it will split it's own characters :)
