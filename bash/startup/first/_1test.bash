_relative_path() {
    # examle of using python! especially useful for advanced scripts
    python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1]))' "$1"
}

expect_equal() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Expected '$expected', got '$actual'}"
    if [[ "$expected" != "$actual" ]]; then

        # * warn if line #s are wrong
        # FYI something is off when I call test_expand_abbr in a shell (REPL)
        #   something about line numbers is funky per `man bash` and just looking at the output here:
        #   IIUC there is a diff formula for correlating line to file/func depending on how smth was invoked... UGH to say the least
        declare -p BASH_SOURCE BASH_LINENO FUNCNAME BASH_ARGC BASH_ARGV BASH_ARGV0 | bat -l bash
        local last_index last_funcname
        ((last_index = ${#FUNCNAME[@]} - 1))
        last_funcname="${FUNCNAME[$((${#FUNCNAME[@]} - 1))]}"
        declare -p last_index last_funcname | bat -l bash
        if [[ "$last_funcname" != "source" ]]; then
            # IOTW if test_expand_abbr called directly in REPL... then line #s are off
            echo
            echo
            echo "WARNING line #s are probably wrong, just affects the source dump below..."
            echo "  ABBR_DEBUG=1 ABBR_TESTS=1 bash"
            echo "  ABBR_DEBUG=1 ABBR_TESTS=1 source '$HOME/repos/github/g0t4/dotfiles/bash/startup/first/_abbr.bash'"
            echo
            true
        fi
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

label_test() {
    echo -e "${PROMPT_CYAN}TEST:${PROMPT_RESET} ${PROMPT_BOLD}${PROMPT_ITALIC}$*${PROMPT_RESET}"
}
