# useful for understanding word splitting + quoting:
inspect() {
    # this intermediate function is JUST to auto enable/disable xtrace...
    # totally fine to  set-x yourself and just call _inspect directly...
    # much less mental overhead to understand what's going on!
    # which for beginners is superior to hand waving away what this mess does:
    ( set -x; _inspect "$@" )
}

_inspect() {
    declare count=0
    for a in "$@"; do
        echo "$count: $a"
        ((count++))
    done
}

foo=(a "b c" d e fg)
inspect "${foo[@]}"

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
