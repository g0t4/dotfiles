function help_bat() {
    help "$@" | bat -l help
}

# BTW HISTFILESIZE defaults to HISTSIZE (controls # entries in ~/.bash_history)
HISTSIZE=1000000
# set | grep -i HIST   # to review values

alias cdr='cd "$(_repo_root)"'

alias ..="cd .."
alias ...="cd ..."
alias ....="cd ...."
alias .....="cd ....."

if [[ "$(uname)" = "Darwin" ]]; then
    alias sed=gsed
fi

# * z wrapper around fish's z command!
z_echo() {
    fish -c "z --echo $*"
}
z() {
    dir="$(z_echo "$@")"
    last_rc=$?
    if ((last_rc != 0)); then
        echo "$dir" # show fail message from z command
        return $last_rc
    fi
    cd "$dir" || return 1
}

last_status() {
    local last_rc=$?
    if ((last_rc == 0)); then
        echo "✅ Success (exit code 0)"
    else
        echo "❌ Failed with exit code $last_rc"
    fi
}

modify_command() {
    local cmd=$READLINE_LINE
    READLINE_LINE="${cmd^^} "         # convert to uppercase, append space too for demo binding to space
    READLINE_POINT=${#READLINE_LINE} # then, move cursor to end too
}

# TODO on space
# bind -x '"\C-x":modify_command'
# bind -x '"\C-a":modify_command'
bind -x '" ":modify_command'   # on space works!
