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

function glX {
    # FYI quoting shouldn't be an issue with passign $1 b/c expansion name has to be all one word
    #   so spaces won't happen within the name
    fish -c "glX $1"
}

function gdlcX {
    # leave bash impl as example but lets defer to fish:
    # local -i num prev
    # num="${1/gdlc/}"
    # ((prev = num - 1))
    # echo "git log --patch HEAD~$num..HEAD~$prev"
    fish -c "gdlcX $1"
}

function glpX {
    # local expanded=${1/glp/git log --patch -}
    # echo "$expanded"
    fish -c "glpX $1"
}

function glsX {
    # local expanded=${1/gls/git log --stat -}
    # echo "$expanded"
    fish -c "glsX $1"
}

function gdsX {
    fish -c "gdsX $1"
}

# treehX
# pstreeX
# treeuX
# treeX
# treedX
