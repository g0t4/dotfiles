#
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
