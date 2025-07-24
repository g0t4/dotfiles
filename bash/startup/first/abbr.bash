declare -A abbrs=()
declare -A abbrs_no_space_after=()
declare -A abbrs_set_cursor=()
declare -A abbrs_anywhere=()
expand_abbr() {
    local key="$1"

    # * pseudo-tokenize (prefix / word_before_cursor / cursor / suffix)
    local line_before_cursor="${READLINE_LINE:0:READLINE_POINT}"
    local word_before_cursor="${line_before_cursor##* }"
    local word_start_offset=$((READLINE_POINT - ${#word_before_cursor}))
    local prefix="${READLINE_LINE:0:word_start_offset}"
    local suffix="${READLINE_LINE:READLINE_POINT}"

    local expanded=""
    if [[ "$word_before_cursor" != "" ]]; then
        expanded="${abbrs[$word_before_cursor]}"
    fi

    # * add_char
    local add_char=" "
    local no_expand_add_char=" " # -NoSpaceAfter does not apply if no expansion
    if [[ "$key" == "enter" ]]; then
        # for enter we have the \C-j in the bind macro, not doing that here
        add_char=""
        no_expand_add_char=""
    fi
    if [[ "$word_before_cursor" && "${abbrs_no_space_after["$word_before_cursor"]}" ]]; then
        add_char=""
    fi

    local anywhere="no"
    if [[ "$word_before_cursor" && "${abbrs_anywhere["$word_before_cursor"]}" ]]; then
        anywhere="yes"
    fi

    local allowed_position="no"
    if [[ $word_start_offset -eq 0 || $anywhere == "yes" ]]; then
        allowed_position=yes
    fi

    if [[ "$expanded" == "" || $allowed_position == "no" ]]; then
        # no expansion => insert char and return early
        READLINE_LINE="${prefix}${word_before_cursor}${no_expand_add_char}${suffix}"
        READLINE_POINT=$((${#prefix} + ${#word_before_cursor} + ${#no_expand_add_char}))
        return 0
    fi

    # * inject expansion and move cursor
    if [[ "${abbrs_set_cursor["$word_before_cursor"]}" ]]; then
        # * --set-cursor

        # locate % in the expanded text
        local expand_char="%"
        local before_cursor="${expanded%%"${expand_char}"*}" # everything before %
        local after_cursor="${expanded#*"${expand_char}"}"   # everything after %
        # effectively strips the % char (b/c its the cursor marker)
        # PRN map diff char than % ONLY IF issues with %... i.e. would mean I need an abbr that has % in the expanded text AND --set-cursor at same time

        READLINE_LINE="${prefix}${before_cursor}${after_cursor}${add_char}${suffix}"
        READLINE_POINT=$((${#before_cursor} + ${#prefix}))
    else
        # * cursor moves afte expanded/add_char

        READLINE_LINE="${prefix}${expanded}${add_char}${suffix}"
        # move cursor right AFTER add_char (so if in middle of line, won't go to end)
        READLINE_POINT=$((${#prefix} + ${#expanded} + ${#add_char}))
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

command_exists() {
    command -v "$1" 1>/dev/null
}

abbr() {
    # PRN handle options (if any) when I add abbrs that use them
    # PRN do I need to slice all remaining args?
    abbrs["${1}"]="${2}"

    if ! command_exists "$1"; then

        # if a command exists, then we don't want to mask it, the whole point of an abbr is to alter what is typed
        # - and if the command exists then the abbr is naturally tab completable
        # if a command doesn't exist, then we need at least a stub to get tab completion
        # - and I am allowing for fallback to execute the abbr since it IS NOT shadowing another underlying command
        # - FYI another choice is to have the stub WARN that abbrs are NEVER executable and only attach those to abbrs that don't shadow a command

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

    # else
    #     # i.e.
    #     #   abbr ls lsd
    #     echo WARN "$1" is a real command and will be shadowed by the fallback function
    #     # TODO I don't need the fallback function if the abbr maps to a command that already exists
    #     #
    #     # WHY this matters, say I have:
    #     # abbr ls lsd
    #     # abbr la "ls -alh"
    #     #
    #     # user types `la` and this is what's run:
    #     # ls -alh
    #     #   # in this case the ls function is called from ls abbr, not the ls command

    fi

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
        # TODO remove -g support?
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
ealias ea='echo "${%[@]}"' -g --set-cursor

abbr pIFS "echo -n \"\${IFS}\" | hexdump -C" # block word splitting, or it will split it's own characters :)
