if ! is_interactive; then
    return
fi

# Colors
# FYI I use these in other spots since its an easy prefix to hunt down should I want to remove/rename it
PROMPT_RESET="\[\e[0m\]"
PROMPT_RED="\[\e[31m\]"
PROMPT_GREEN="\[\e[32m\]"
PROMPT_YELLOW="\[\e[33m\]"
PROMPT_BLUE="\[\e[34m\]"
PROMPT_MAGENTA="\[\e[35m\]"
PROMPT_CYAN="\[\e[36m\]"
PROMPT_BOLD="\[\e[1m\]"
PROMPT_UNDERLINE="\[\e[4m\]"
PROMPT_ITALIC="\e[3m"

prompt_current_dir() {
    # FYI! NOT INTENDED FOR DEMOS IN COURSE
    #  JUST ADDED THIS TO shorten dir name a bit
    current_dir="${PWD##*/}"
    current_dir="${current_dir/pri*course-bash*/pri-bash}"
}

__last_histcmd=0
__last_rc=0
show_rc_when_last_cmd_failed() {
    local last_rc=$?
    local curr_histcmd=$HISTCMD

    # edge triggered on change in HISTCMD
    # HISTCMD only increments when a command is exectued
    # ENTER on empty cmdline will not increment it b/c that's not a command
    # thus we only show if HISTCMD changes indicating previous command just failed and this is prompt right after
    if ((curr_histcmd != __last_histcmd)); then
        __last_histcmd=$curr_histcmd

        if ((last_rc != 0)); then
            # prints message ABOVE next prompt, by echo'ing in a PROMPT_COMMAND function
            echo -e "\033[31mCommand failed with exit code $last_rc\033[0m"
        fi
    fi
}

PROMPT_COMMAND="show_rc_when_last_cmd_failed;prompt_current_dir"
PS1="${PROMPT_CYAN}${PROMPT_BOLD}${PROMPT_UNDERLINE}\${current_dir}${PROMPT_RESET} \$ "

# PROMPT_DIR_COLOR="${PROMPT_CYAN}${PROMPT_BOLD}${PROMPT_UNDERLINE}\W${PROMPT_RESET}"

# LAST_CMDLINE_STATUS=' [PIPE: ${PIPESTATUS[*]} ] $?'
# PS1="${PROMPT_USER_COLOR}${PROMPT_HOST_COLOR}${PROMPT_DIR_COLOR}${LAST_CMDLINE_STATUS} \$ "
export PS1
