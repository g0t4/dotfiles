_relative_path() {
    # examle of using python! especially useful for advanced scripts
    python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1]))' "$1"
}

expect_equal() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Expected '$expected', got '$actual'}"
    if [[ "$expected" != "$actual" ]]; then

        # FYI something is off when I call test_expand_abbr in a shell (vs via bashrc)... via bashrc is working so use that for now
        #   something about line numbers is funky per `man bash` and just looking at the output here:
        #   IIUC there is a diff formula for correlating line to file/func depending on how smth was invoked... UGH to say the least
        # declare -p BASH_SOURCE BASH_LINENO FUNCNAME BASH_ARGC BASH_ARGV BASH_ARGV0  | bat -l bash
        #
        # # FYI FUNCNAME is shifted by 1 - b/c it has caller's funcname for each "stack frame"
        # for i in "${!BASH_SOURCE[@]}"; do
        #     echo "Index $i: ${BASH_SOURCE[$i]}"
        #     echo "          ${FUNCNAME[$i]}"
        #     echo "          ${BASH_LINENO[$i]}"
        # done

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

expect_function_exists() {
    local name="$1"
    local must_contain="$2" # OPTIONAL ARG to verify definition contains this string (i.e. subset of code)

    if ! declare -F "$name" >/dev/null; then
        local file=$(_relative_path "${BASH_SOURCE[1]}")
        local line="${BASH_LINENO[0]}"
        echo "  ❌ $file:$line — Expected function '$name' to exist" >&2
        echo -n "  "
        bat --line-range "$line" "$file"
        return 1
    fi

    if [[ -n "$must_contain" ]]; then
        local body
        body=$(declare -f "$name")
        if [[ "$body" != *"$must_contain"* ]]; then
            local file=$(_relative_path "${BASH_SOURCE[1]}")
            local line="${BASH_LINENO[0]}"
            echo "  ❌ $file:$line — Function definition (for '$name') does not contain: $must_contain" >&2
            echo -n "  "
            bat --line-range "$line" "$file"

            echo "body:"
            echo "$body" | bat -l bash

            return 1
        fi
    fi
}

expect_function_not_defined() {
    # do not need to check body, just verify an obscure name in test cases so you don't have to over complicate this!

    local name="$1"
    if declare -F "$name" >/dev/null; then
        local file=$(_relative_path "${BASH_SOURCE[1]}")
        local line="${BASH_LINENO[0]}"
        echo "  ❌ $file:$line — Function should not exist, named: '$name'" >&2
        echo -n "  "
        bat --line-range "$line" "$file"

        local body=$(declare -f "$name")
        echo "body:"
        echo "$body" | bat -l bash

        return 1
    fi
}

start_test() {
    label_test "$@"
    "$@"
}

# Text attributes
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m" # Not supported in all terminals
UNDERLINE="\e[4m"
REVERSED="\e[7m"

# * Regular colors
BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"

# * Bold + color (single merged sequence)
BOLD_BLACK="${BOLD}\e[30m"
BOLD_RED="${BOLD}\e[31m"
BOLD_GREEN="${BOLD}\e[32m"
BOLD_YELLOW="${BOLD}\e[33m"
BOLD_BLUE="${BOLD}\e[34m"
BOLD_MAGENTA="${BOLD}\e[35m"
BOLD_CYAN="${BOLD}\e[36m"
BOLD_WHITE="${BOLD}\e[37m"

# 256 colors - 8-bit color
# ESC[38;5;{ID}m	Set foreground color.
# ESC[48;5;{ID}m	Set background color.

# Example usage
label_test() {
    echo -e "${BOLD_CYAN}TEST:${RESET} ${BOLD}${ITALIC}$*${RESET}"
}
