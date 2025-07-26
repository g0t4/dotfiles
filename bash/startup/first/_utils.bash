
indexed_array_contains() {

    # usage:
    #   arr=(foo bar baz)
    #   indexed_array_contains "bar" "${arr[@]}" && echo "found"

    local val=$1
    shift # remove val (first positional param) off of $@
    for item in "$@"; do
        [[ $item == "$val" ]] && return 0
    done
    return 1
}
