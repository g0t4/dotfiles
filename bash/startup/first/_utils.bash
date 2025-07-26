indexed_array_contains() {
    # FYI ideally would use associative array so O(1) lookup vs O(n) below

    # usage:
    #   arr=(foo bar baz)
    #   indexed_array_contains "bar" "${arr[@]}" && echo "found"

    local value="$1"
    shift # remove val (first positional param) off of $@
    for item in "$@"; do
        [[ "$item" == "$value" ]] && return 0
    done
    return 1
}
