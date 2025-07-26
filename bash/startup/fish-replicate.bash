#
# * status command
# status
# status is-interactive-read
# status is-block
# status is-breakpoint
# status is-command-substitution
# status is-no-job-control
# status is-full-job-control
# status is-interactive-job-control
# status current-command
# status current-commandline
# status filename
# status basename
# status dirname
# status fish-path
# status function
# status line-number
# status stack-trace
# status job-control CONTROL_TYPE
# status features
# status test-feature FEATURE
# status buildinfo

# status() {
#     case "$1" in
#         "is-login")
#             shopt -q login_shell
#             ;;
#         "is-interactive")
#             [[ $- == *i* ]]
#             ;;
#     esac
# }
# FYI would need completions for subcommands, so lets use __ instead to get top level completion for free

# status__is-login && echo yes
status__is-login() {
    shopt -q login_shell
}

# status__is-interactive && echo yes
status__is-interactive() {
    [[ $- == *i* ]]
}

# FYI! the string commands are a great way to test understanding of IFS in bash (word splitting, quoting/expansion, etc)

# string__split_read : "$BASHOPTS:a:b c"
# string__split "delimiter" "string"
# string__split_for : "$BASHOPTS"
# ONLY TAKES TWO ARGS, careful with word splitting!
string__split_for() {
    local IFS="$1"
    # shellcheck disable=SC2068 # Double quote array expansions to avoid re-splitting elements.
    local string="$2"
    for part in $string; do
        echo "$part"
    done
    # TODO add option to split STDIN
}
string__split_read() {
    local IFS="$1"
    local string="$2"
    read -ra parts <<<"$string"
    for part in "${parts[@]}"; do
        echo "$part"
    done
    # TODO add option to split STDIN
}

string__join() {
    local IFS="$1"
    shift

    if [[ -t 0 ]]; then
        # string__join | foo bar bam
        # each argument is an item (after $1, hence shift above)
        # CAREFUL with word splitting if passing strings as args!
        echo "$*"
    else
        # string__split_read : "$BASHOPTS:a:b c" | string__join "|"
        # each line is an item
        mapfile -t parts
        echo "${parts[*]}"
    fi
}
