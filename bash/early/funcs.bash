# useful for understanding word splitting + quoting:
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

# challenge to write down what you will see _inspect _____ before run them
# set -x
foo=(a "b c" d " " fg)
echo
echo "quoted @"
inspect "${foo[@]}"
# _inspect a 'b c' d ' ' fg
echo
echo "quoted *"
inspect "${foo[*]}"
# _inspect 'a b c d   fg' # take quoted @ version and put outer quoutes around all of it and leave space between each arg
echo
echo unquoted @
inspect ${foo[@]}
# _inspect a b c d fg   # take quoted @ version and delete all quotes around elements, then word split all of it (no quotes)
echo
echo unquoted *
inspect ${foo[*]}
# _inspect a b c d fg  # strip all quotes from quoted @ version and then split words on everything (within and between elements)


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
