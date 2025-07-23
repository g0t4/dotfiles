# Colors
RESET="\[\e[0m\]"
RED="\[\e[31m\]"
GREEN="\[\e[32m\]"
YELLOW="\[\e[33m\]"
BLUE="\[\e[34m\]"
MAGENTA="\[\e[35m\]"
CYAN="\[\e[36m\]"
BOLD="\[\e[1m\]"
UNDERLINE="\[\e[4m\]"

# Components
# USER_COLOR="$GREEN\u$RESET"
USER_COLOR=""
# HOST_COLOR="$BLUE@\h$RESET"
HOST_COLOR=""

prompt_current_dir() {
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
PS1="${CYAN}${BOLD}${UNDERLINE}\${current_dir}${RESET} \$ "

# DIR_COLOR="${CYAN}${BOLD}${UNDERLINE}\W${RESET}"

# LAST_CMDLINE_STATUS=' [PIPE: ${PIPESTATUS[*]} ] $?'

# # Prompt
# PS1="${USER_COLOR}${HOST_COLOR}${DIR_COLOR}${LAST_CMDLINE_STATUS} \$ "
#
# Optional: export for subshells
export PS1
