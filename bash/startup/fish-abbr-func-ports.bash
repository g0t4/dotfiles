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

# #function gp_uptoX
#     set -l num (string replace --regex '^gp_upto' '' $argv)
#     # refspec has object:dest_ref
#     # TODO also use default remote? or?
#     echo "git push origin HEAD~$num:$(git_current_branch)"
# end

function git_unpushed_commits {
    fish -c "git_unpushed_commits"
}

glX() {
    #  gl10 / gl
    local expanded="${1/gl/git log -}"
    echo "${expanded% -}" # strip trailing ' -' if no number passed
}
# abbr git_log_num --regex 'gl[0-9]*' --function _expand_git_log

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
