declare -A abbrs=()
declare -A abbrs_no_space_after=()
declare -A abbrs_set_cursor=()
declare -A abbrs_anywhere=()
expand_abbr() {
    local key="$1"
    # local command_line=$READLINE_LINE # full line
    local line_before_cursor="${READLINE_LINE:0:READLINE_POINT}"
    local word_before_cursor="${line_before_cursor##* }"
    local word_start_offset=$((READLINE_POINT - ${#word_before_cursor}))
    local prefix="${READLINE_LINE:0:word_start_offset}"
    local suffix="${READLINE_LINE:READLINE_POINT}"

    # echo $word_before_cursor

    # TODO take cursor position and get word before, including offsets, so I can replace anywhere in commandline...
    #    then when I have that, I can add a global (-g) flag like I have in ealias in zsh
    local expanded=""
    if [[ "$word_before_cursor" != "" ]]; then
        expanded="${abbrs[$word_before_cursor]}"
    fi

    # * add_char
    local add_char=" "
    if [[ "$key" == "enter" ]]; then
        add_char=""
    fi
    if [[ "$word_before_cursor" && "${abbrs_no_space_after["$word_before_cursor"]}" ]]; then
        add_char=""
    fi

    if [[ "$expanded" == "" ]]; then
        # no expansion => insert char and return early
        READLINE_LINE="${prefix}${word_before_cursor}${add_char}${suffix}"
        READLINE_POINT=$((${#prefix} + ${#word_before_cursor} + ${#add_char}))
        return 0
    fi

    # replace word w/ expanded text
    READLINE_LINE="${prefix}${expanded}${add_char}${suffix}"

    # * position cursor
    if [[ "${abbrs_set_cursor["$word_before_cursor"]}" ]]; then
        local before_cursor="${expanded%%\%*}" # everything before %
        local after_cursor="${expanded#*\%}"   # everything after %
        # effectively strips the % char (b/c its the cursor marker)
        # PRN map diff char than % ONLY IF issues with %... i.e. would mean I need an abbr that has % in the expanded text AND --set-cursor at same time

        # TODO do replace and calculate within ${expanded} ONLY... not entrie cmdline
        #   for now full will be fine, but if I have the % in the prefix/suffix then it might be an issue (esp in prefix)
        #   as that would have nohting to do with the current expansion

        READLINE_LINE="${before_cursor}${after_cursor}${add_char}"
        READLINE_POINT="${#before_cursor}"
    else
        READLINE_POINT=${#READLINE_LINE}
    fi

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

# command_not_found_handle() {
#     # TODO capture existing command_not_found_handle func and call it too?
#     # FYI type out `gst --short` and use Ctrl-j to submit and test this w/o expanding:
#     exec_abbr "$@"
# }

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

    # define function for tab completion
    # - thus, body is irrelevant for tab completion purposes (can be no-op :;, or true; )
    # - i.e. g<TAB> includes abbrs starting with g!
    # AND, have body call exec_abbr instead of command_not_found_handle global fallback
    # - leave this to exec_abbr, don't try to fully inline ${2} as weird cases will arise and break creating the function
    #   - i.e. gcmsg that inserts only opening " ... user would need `gcmsg foo\"` to get it to form a working command with the abbr prefix
    # - passing $@ too means whatever options come after an abbreviation are passed to exec_abbr
    # FYI this can fire if user bypasses abbr expansion (i.e. Ctrl-j)
    #   i.e. `gst --short`
    eval "function ${1} { exec_abbr '${1}' \"\$@\"; }"
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

    shift # avoid matching on the name=value positional arg $1
    # remaining args are all for abbr registration, not part of expanded text
    if indexed_array_contains "--NoSpaceAfter" "${@}"; then
        abbrs_no_space_after["$key"]=yes
    fi
    if indexed_array_contains "-g" "${@}" ||
        indexed_array_contains "--position=anywhere" "${@}"; then
        # PRN move -g to --position=anywhere like in fish shell?
        abbrs_anywhere["$key"]=yes
    fi
    if indexed_array_contains "--set-cursor" "${@}"; then
        # FYI for now we will only work with % (fish default) that way I don't have to parse that here too
        abbrs_set_cursor["$key"]=yes
    fi
}

abbr gst "git status"
abbr gdlc "git log --patch HEAD~1..HEAD"

# ealias gcmsg='git commit -m "' --NoSpaceAfter
ealias gcmsg='git commit -m "%"' --NoSpaceAfter --set-cursor
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
