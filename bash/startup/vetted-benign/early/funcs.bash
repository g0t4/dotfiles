# useful for understanding expansion + word splitting + quoting:
inspect() {
    # goal enable xtrace such that the output is the same as what you'd see with any set of args
    # inspect ${foo[@]}
    # _inspect ${foo[@]}
    ( set -x; _inspect "$@" )
    # FYI if passing "$@" seems confusing early on in demos, just set -x and call _inspect directly...
}

_inspect() {
    declare count=0
    for a in "$@"; do
        echo "$count: $a"
        ((count++))
    done
}

# foo=(a "b c" d e fg)
# inspect "${foo[@]}"

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

# is-login && echo yes
is-login() {
    shopt -q login_shell
}

# is-interactive && echo yes
is-interactive() {
    [[ $- == *i* ]]
}

is-history-expansion-enabled() {
    [[ $- == *H* ]]
}

is-brace-expansion-enabled() {
    [[ $- == *B* ]]
}

is-no-clobber-enabled() {
    [[ $- == *C* ]]
}

is-pathname-expansion-disabled() {
    # aka globbing
    [[ $- == *f* ]]
}

explain-set-option() {
    declare -A set_options=(
        "a" "Auto-export variables"
        "b" "Job term. notify"
        "e" "Exit on error"
        "f" "No globbing (pathname exp.)"
        "h" "Hash commands"
        "k" "Env vars on assign?"
        "m" "Job control"
        "n" "Read commands, no exec"

        # TODO -o
    )

    local -i count
    local num_options="${#-}"
    for ((count = 0; count < num_options; count++)); do
        local char="${-:$count:1}" #$ name:start:length
        echo "$count: $char"
    done

}

# *** STDIO

readonly FD_STDIN=0
readonly FD_STDOUT=1
readonly FD_STDERR=2

is_a_terminal() {
    test -t "$1"
}
is_stdin_a_terminal() {
    is_a_terminal "$FD_STDIN"
}
is_stderr_a_terminal() {
    is_a_terminal "$FD_STDERR"
}
is_stdout_a_terminal() {
    is_a_terminal "$FD_STDOUT"
}

# * repeat

function repeat() {
    # repeat . 3
    # repeat ../ 4

    local string="$1"
    local times="$2"
    local -i count
    for ((count = 0; count < "$times"; count++)); do
        echo -n "$string"
    done
}

tests_for_repeat() {

    label_test repeat ../ 3
    repeated="$(repeat ../ 3)"
    expect_equal "$repeated" "../../../"

    label_test repeat . 0
    repeated="$(repeat . 0)"
    expect_equal "$repeated" ""

}
