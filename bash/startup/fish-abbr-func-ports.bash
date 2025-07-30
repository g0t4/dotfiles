function find_missing_abbr_functions {
    for f in "${abbrs_function[@]}"; do
        # FYI declare -F will show name if it exists, otherwise show "MISSING" with name!
        #  yeah this is a bit much trickery but w/e
        if ! declare -F "$f"; then
            echo MISSING $f
        fi
    done
}

# ports of functions for fish abbrs... both regex and non-regex abbrs
function gdlcX {
    local -i num prev
    num="${1/gdlc/}"
    ((prev = num - 1))
    echo "git log --patch HEAD~$num..HEAD~$prev"
}

function glsX {
    # string replace --regex '^gls' 'git log --stat -' $argv
    local expanded=${1/gls/git log --stat -}
    echo "${expanded# -}" # strip trailing ' -' if no # provided
    # TODO gls right now is standalone alias, that is a bit diff... do I want to merge it here and have it behave like gls1 etc?
}

# glpX
# gp_uptoX
# treehX
# pstreeX
# treeuX
# treeX
# _grvcp
# gdsX
# treedX
