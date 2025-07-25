_relative_path() {
    # examle of using python! especially useful for advanced scripts
    python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1]))' "$1"
}

expect_equal() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Expected '$expected', got '$actual'}"
    if [[ "$expected" != "$actual" ]]; then
        local caller_file
        caller_file=$(_relative_path "${BASH_SOURCE[1]}")
        local caller_line_num="${BASH_LINENO[0]}"

        echo "  ❌ $caller_file:$caller_line_num — $message" >&2
        echo -n "  "
        # print the calling line:
        bat --line-range "${caller_line_num}" "$caller_file"
        return 1
    fi
}

# pipx install rich-cli
start_test() {
    label_test "$@"
    "$@"
}

CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"
label_test() {
    echo -e "${BOLD}${CYAN}TEST:${RESET} $*"
}
