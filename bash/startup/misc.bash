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

# *** nvim

# open file and select line range!
#    use with :CopyFileSystemLink cmd
# nvselect ~/repos/github/g0t4/dotfiles/.config/nvim/lua/non-plugins/github-links.lua:83
nvselect() {
    local link="$1"          # path/too/foo.txt:10-20
    local file="${link%%:*}" # path/to/foo.txt (strip off line range)

    # split up start/end line (if present)
    local start_line end_line
    IFS='-' read -r start_line end_line <<<"${link#*:}"
    end_line=${end_line:-$start_line} # default end to start line

    # launch neovim
    # jump to startline, i.e. +10
    # normal mode V (linewise selection)
    # end-start = # lines in range... then j... so pressing down arrow effectively for # lines in selection to move to end of selection
    # last part is file path
    # zz centers
    nvim +"${start_line}" +"normal! V$((end_line - start_line))jzz" "$file"
}

# *** bind

# bind reminder abbrs:
#  "reminder" abbrs b/c they help quickly find commands/options I forgot about
#  tab complete shows these bind_<TAB> => pick one => expands!
abbr bind_list_all "bind -p; bind -s; bind -X"
abbr bind_list_macros "bind -s"
#
abbr bind_list_bash_funcs "bind -X"
# TODO bind -x doesn't work to give executable format... is there another way to match -s/-p (little s/p) ... -S/-P/-X are all "human readable" ... why isn't there an exec format for -X?!
