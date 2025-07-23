function help_bat() {
    help "$@" | bat -l help
}

# BTW HISTFILESIZE defaults to HISTSIZE (controls # entries in ~/.bash_history)
HISTSIZE=1000000
# set | grep -i HIST   # to review values

function _repo_root() {

    if git rev-parse --is-inside-work-tree 1>/dev/null 2>&1; then
        # ignore STDOUT/STDERR if git is missing OR not in work tree (repo)
        git rev-parse --show-toplevel 2>/dev/null
    elif hg root >/dev/null 2>&1; then
        # ignore STDOUT/STDERR if hg command is missing OR not in hg repo
        hg root 2>/dev/null
    else
        # warn over STDERR (that way, cd $(_repo_root) still works)
        echo "cannot find repo root" >&2
        builtin pwd
    fi
}

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
