#
# * shell options
#
# shopt -s globstar # match ** matches all files + zero+ directories (basically search all nested dirs)
shopt -s autocd     # cd to a dir with just its name in command position
# shopt -s histreedit # failed history expansions - put back into cmdline to edit (otherwise they are lost)

# abbr options_list_set "echo \$-"
# abbr options_list_shopt "shopt"
# abbr options_list_shopt_executable "shopt -p"

#
# * env vars (without a different home)
[[ -z "$TERM" || "$TERM" = dumb ]] && TERM=xterm-256color
export EDITOR=nvim
export GREP_COLOR="1;38;5;162"
export RIPGREP_CONFIG_PATH="$WES_DOTFILES/.config/ripgrep/ripgreprc"
export DOCKER_HIDE_LEGACY_COMMANDS=1
export KUBECTL_EXTERNAL_DIFF="icdiff -r"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
# export NODE_OPTIONS=--disable-warning=ExperimentalWarning
# export ICDIFF_OPTIONS="--highlight"
# VAGRANT_BOX_UPDATE_CHECK_DISABLE=
# VAGRANT_EXPERIMENTAL=
# VAGRANT_PROVIDER=

alias grep="grep --color=auto"

function help_bat() {
    help "$@" | bat -l help
}

# BTW HISTFILESIZE defaults to HISTSIZE (controls # entries in ~/.bash_history)
HISTSIZE=1000000
# set | grep -i HIST   # to review values

alias cdr='cd "$(_repo_root)"'

# * leave these for demo examples and then remove when course series is done:
# alias ..="cd .."
# alias ...="cd ..."
# alias ....="cd ...."
# alias .....="cd ....."

# add if needed later, this could mess me up if I forget I set this
# FYI do your sed demos on a linux machine?
# if [[ "$(uname)" = "Darwin" ]]; then
#     alias sed=gsed
# fi

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

# *** diff

_abbr_expand_diff_last_two_commands() {

    if ! is-history-expansion-enabled; then
        echo "HISTORY EXPANSION MUST BE ENABLED, use 'set -B' to do so" >&2
    fi
    echo 'icdiff <(!-1) <(!-2)'
}

# *** dirs

take() {
    local dir="${1}"
    if [[ -z "$dir" ]]; then
        echo "take requires at least a new directory to create and optionally files to move into it"
        echo "usage:"
        echo "'take newdir [file1 file2 ...]'"
        return 1
    fi

    mkdir -p -- "$dir"

    # strip arg1
    shift

    if (($# > 0)); then
        mv -- "$@" "$dir"
    fi

    cd -- "$dir" || return # || return for shellcheck
}

# *** lsof
abbr 'lsof_bash_shell' 'sudo lsof -p $$'

function multicd {
    # for abbr
    local -i num_dots
    num_dots="${#1}"
    ((up_dirs = num_dots - 1))
    echo -n "cd "
    repeat ../ $up_dirs
}
