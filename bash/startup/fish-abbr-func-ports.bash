function find_missing_abbr_functions {
    for f in "${abbrs_function[@]}"; do
        # FYI declare -F will show name if it exists, otherwise show "MISSING" with name!
        #  yeah this is a bit much trickery but w/e
        if ! declare -F "$f"; then
            echo MISSING $f
        fi
    done
}

# *** ports of functions for fish abbrs... both regex and non-regex abbrs

_grvcp() {
    # * DO NOT MIGRATE ANYTHING YOU CAN JUST CALL!
    fish -c "_grvcp"
}

function gp_uptoX {
    # TODO! drop arg2 READLINE_POINT from abbr calling code?
    # TODO what does fish pass? just cmdline?
    # FYI arg 2 is cursor position which isn't used here... in fact I probably shouldn't pass that given fish shell doesn't?
    #  or I could use READLINE_POINT which yes I shouldn't do but I could when it is crucial
    local cmdline="$1"
    fish -c "gp_uptoX $cmdline"
}

function git_unpushed_commits {
    fish -c "git_unpushed_commits"
}

glX() {
    fish -c "glX $1"
}

function gdlcX {
    local -i num prev
    num="${1/gdlc/}"
    ((prev = num - 1))
    echo "git log --patch HEAD~$num..HEAD~$prev"
}

function glpX {
    # string replace --regex '^glp' 'git log --patch -' $argv
    local expanded=${1/glp/git log --patch -}
    echo "$expanded"
    # FYI right now glp is not mapped here
}

function glsX {
    # string replace --regex '^gls' 'git log --stat -' $argv
    local expanded=${1/gls/git log --stat -}
    echo "$expanded"
    # FYI right now gls is not mapped here
}

# function gdsX
#     # too bad `git diff -X` doesn't exist (submit a PR?)
#     #   instead have to set start/stop commit refs
#     echo -n (string replace --regex '^gds' 'git diff --stat HEAD~' $argv)'..HEAD'
# end

# treehX
# pstreeX
# treeuX
# treeX
# treedX
