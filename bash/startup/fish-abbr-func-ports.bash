# ports of functions for fish abbrs... both regex and non-regex abbrs
function gdlcX {
    local -i num prev
    num="${1/gdlc/}"
    ((prev = num - 1))
    echo "git log --patch HEAD~$num..HEAD~$prev"
}
