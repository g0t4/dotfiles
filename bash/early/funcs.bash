# useful for understanding word splitting + quoting:
inspect() {
    declare -i count=0
    for a in "$@"; do
        echo $count: $a
        count=count+1
    done
}

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
