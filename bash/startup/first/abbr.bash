source _test.bash 2>/dev/null || true # ignore load failure, source is for bash LS (i.e. F12) and shellcheck

declare -A abbrs=()
declare -A abbrs_no_space_after=()
declare -A abbrs_set_cursor=()
declare -A abbrs_anywhere=()
declare -A abbrs_function=()
declare -A abbrs_regex=()
declare -A abbrs_command=()
declare -A abbrs_stub_func_names=()

is_no_space_after_set() {
    local word="$1"
    [[ -n "$word" && "${abbrs_no_space_after["$word"]}" = "yes" ]]
}

is_anywhere_allowed() {
    local word="$1"
    [[ -n "$word" && "${abbrs_anywhere["$word"]}" = "yes" ]]
}

lookup_only_cmd() {
    local word="$1"
    if [[ -z "$word" ]]; then
        # key lookup fails if subscript is empty b/c it's treated as passing no subscript! foo[""] => foo[]
        echo -n ""
        return
    fi
    echo -n "${abbrs_command["$word"]}"
}

lookup_cursor_set_char() {
    local word="$1"
    if [[ -z "$word" ]]; then
        echo ""
        return 1
    fi
    echo "${abbrs_set_cursor["$word_before_cursor"]}"
}

lookup_expanded() {
    local word="$1"
    if [[ -z "$word" ]]; then
        echo ""
        return 1
    fi
    local regex_value="${abbrs_regex["$word"]}"
    # declare -p regex_value >&2 # use STDERR so don't mess up caller capturing STDOUT
    # cannot match name for regex abbrs
    local abbr_value="${abbrs["$word"]}"
    # declare -p abbr_value >&2 # use STDERR so don't mess up caller capturing STDOUT
    local func="${abbrs_function["$word"]}"
    # declare -p func >&2 # use STDERR so don't mess up caller capturing STDOUT
    if [[ -z "$regex_value" ]]; then
        # abbr matched on NAME is NOT a regex
        if [[ -n "$func" ]]; then
            # 1. prioritize expand function
            "$func" "$READLINE_LINE" "$READLINE_POINT"
            return
        fi
        if [[ -n "$abbr_value" ]]; then
            # 2. if abbr's value is set...
            echo "$abbr_value"
            return
        fi
        # 3. else fall through now to look through all regexes
    fi

    # look at all regexes since we don't have a match yet!
    # TODO review tests to make sure I covered all cases here... I vaguely recall thinking I wasn't covering all cases with regex abbr expands
    local name
    for name in "${!abbrs_regex[@]}"; do
        # declare -p name >&2
        regex="${abbrs_regex["$name"]}"
        # declare -p regex >&2
        # FYI careful with "" around $regex... will force literal match on regex variable's expanded text value (including [0-9] wildcards)
        if [[ "$word" =~ $regex ]]; then
            # lookup func FOR this abbr (not one above)
            local func="${abbrs_function["$name"]}"
            # declare -p func >&2 # * SUPER helpful to see when expanding regexes!
            if [[ -n "$func" ]]; then
                "$func" "$READLINE_LINE" "$READLINE_POINT"
                return
            else
                echo "UNEXPECTED FAILURE: matching regex has NO function"
                return 2
            fi
        fi
    done
    return 1
}

declare -A command_separators=(
    ['|']='|' ['|&']='|&'                       # simple command separator (within pipeline)
    [';']=';' ['||']='||' ['&']='&' ['&&']='&&' # pipeline separator (within lists)
    # \n (newline)
    [')']=')' ['}']='}'     # compound commands
    ['((']='((' ['[[']='[[' # compound arithmethic, conditional exprsesions
    # TODO newline too? first command on line?
)

_dump_var() {
    # FYI defined as a function so I can add error handling
    #   and so not tied to declare -p

    declare -p "${1}" | bat -l bash

    # FYI I want to see difference between empty/not defined:
    #   declare -- only_cmd=""
    #   bash: declare: first_word: not found
}

_dump_expand_locals() {
    if [[ -z "$ABBR_DEBUG" ]]; then
        return
    fi

    # rely on bash's dynamic scope to access caller's variables w/o explicitly passing them

    _dump_var READLINE_LINE
    _dump_var READLINE_POINT
    _dump_var line_before_cursor
    _dump_var word_before_cursor
    _dump_var word_before_start_offset
    _dump_var previous_word
    _dump_var prefix
    _dump_var suffix
    echo

    _dump_var expanded
    _dump_var expand_func
    echo

    _dump_var add_char
    _dump_var add_char_if_no_expansion
    echo

    _dump_var anywhere
    _dump_var allowed_position
    echo

    _dump_var only_cmd
    _dump_var first_word
    echo

    _dump_var set_cursor_char

}

expand_abbr() {
    local key="$1"

    # * pseudo-tokenize (prefix / word_before_cursor / cursor / suffix)
    local line_before_cursor="${READLINE_LINE:0:READLINE_POINT}"
    local word_before_cursor="${line_before_cursor##* }"
    local word_before_start_offset=$((READLINE_POINT - ${#word_before_cursor}))
    # prefix/suffix are w.r.t. word_before_cursor
    local prefix="${READLINE_LINE:0:word_before_start_offset}"
    local suffix="${READLINE_LINE:READLINE_POINT}"

    local expanded=$(lookup_expanded "$word_before_cursor")

    # * add_char
    local add_char="$key"
    local add_char_if_no_expansion="$key" # --no-space-after does not apply if no expansion
    if [[ "$key" = "enter" ]]; then
        # for enter we have the \C-j in the bind macro, not doing that here
        add_char=""
        add_char_if_no_expansion=""
    fi
    if is_no_space_after_set "$word_before_cursor"; then
        add_char=""
    fi

    local anywhere="no"
    if is_anywhere_allowed "$word_before_cursor"; then
        anywhere="yes"
    fi

    local allowed_position="no"
    local tmp_prefix_for_previous_word="${READLINE_LINE:0:$word_before_start_offset}"
    local previous_word=$(echo "$tmp_prefix_for_previous_word" | awk '{print $NF}') # TODO! just take last char of prior word, not entire word... b/c echo foo;  # trailing semicolon doesn't need a space to terminate the echo
    # TODO add test of ; semicolon for previous_word too and others that I add support for in regex:
    if [[ $word_before_start_offset -eq 0 || ${command_separators["$previous_word"]} || "$anywhere" = "yes" ]]; then
        allowed_position=yes
    fi

    # shellcheck disable=SC2155
    local only_cmd=$(lookup_only_cmd "$word_before_cursor")
    if [[ -n "$only_cmd" ]]; then
        #  cmd (at start of line) matches --command...
        #  use this to set allowed_position (override other checks above)
        local first_word="${READLINE_LINE%% *}" # greedy strip from first space to end of line => thus first command
        if [[ "$only_cmd" = "$first_word" ]]; then
            allowed_position=yes
        else
            allowed_position=no
        fi
    fi

    if [[ "$expanded" = "" || "$allowed_position" = "no" ]]; then
        _dump_expand_locals
        # no expansion => insert char and return early
        READLINE_LINE="${prefix}${word_before_cursor}${add_char_if_no_expansion}${suffix}"
        READLINE_POINT=$((${#prefix} + ${#word_before_cursor} + ${#add_char_if_no_expansion}))
        return 0
    fi

    # * inject expansion and move cursor
    # shellcheck disable=SC2155
    local set_cursor_char=$(lookup_cursor_set_char "$word_before_cursor")
    _dump_expand_locals
    if [[ -n "$set_cursor_char" ]]; then
        # * --set-cursor too
        # i.e. foo%bar => before=foo after=bar
        local before_cursor_char="${expanded%%"${set_cursor_char}"*}" # %% is greedy strip suffix back to first %
        local after_cursor_char="${expanded#*"${set_cursor_char}"}"   # # is (not greedy) strip prefix, up to first %

        READLINE_LINE="${prefix}${before_cursor_char}${after_cursor_char}${add_char}${suffix}"
        READLINE_POINT=$((${#prefix} + ${#before_cursor_char}))
    else
        # * cursor moves after expanded/add_char

        READLINE_LINE="${prefix}${expanded}${add_char}${suffix}"
        # move cursor right AFTER add_char (so if in middle of line, won't go to end)
        READLINE_POINT=$((${#prefix} + ${#expanded} + ${#add_char}))
    fi

}
# * expand on <Space>
bind -x '" ": expand_abbr " "'
bind -x '";": expand_abbr ";"' # so you can:   gst<;> => git status;
bind -x '"|": expand_abbr "|"' # same as ;
bind -m vi-insert -x '" ": expand_abbr " "'
bind -m vi-insert -x '";": expand_abbr ";"'
bind -m vi-insert -x '"|": expand_abbr "|"'
# TODO intercept tab and expand on tab complete too (else right now you have to backup (backspace) and then hit space again)

# * expand on <Return>
expand_hack_enter='\C-x\C-['
# acceptline_hack='\C-x\C-]'
acceptline_hack='\C-j' # OOB accept-line
bind -x "\"$expand_hack_enter\": expand_abbr enter"
bind "\"$acceptline_hack\": accept-line"
bind "\"\C-m\": \"$expand_hack_enter$acceptline_hack\""
bind -m vi-insert -x "\"$expand_hack_enter\": expand_abbr enter"
bind -m vi-insert "\"$acceptline_hack\": accept-line"
bind -m vi-insert "\"\C-m\": \"$expand_hack_enter$acceptline_hack\""

command_exists() {
    command -v "$1" 1>/dev/null
}

_abbr() {
    abbrs["${1}"]="${2}"

    # PRN handle replace gracefully... not sure I need to do anything special?

    # if a command/func exists, don't shadow it, the whole point of an abbr is to alter what is _typed_
    # - thankfully tab completion works fine if it already exists as a command/func!
    # if a command/func doesn't exist, then we need a stub func (or smth else) to get tab completion
    if ! command_exists "$1"; then

        # define function for tab completion
        # - i.e. g<TAB> includes abbrs starting with g!
        # eval "function ${1} { exec_abbr '${1}' \"\$@\"; }" # old design with fallback execution of abbr... would be ok to use again if I really find myself needing this
        eval "function ${1} { echo 'abbrs are not intended to be executed directly (i.e. if you disable abbr expansion)... if you think this is masking a real command, restart your shell to re-create abbrs and this warning will go away'; }"
        abbrs_stub_func_names["$1"]="$1"

        # FYI, for now I am happy checking for shadowed command/function at abbr definition time
        #  if user later:
        #  - adds to the PATH in a way that results in the stub func shadowing a new command
        #    mostly meh b/c, the next time they launch the shell it will fix itself
        #    and I added a warning to the stub func (when it's executed) to warn the user about this!
        #    this all beats trying to detect shadowing at execution time in smth like an updated exec_abbr
        #  - defines new function (will work fine b/c it will shadow the stub func!)
        #
        # * example of shadowing real commands/functions with the stub func:
        #
        # say I define:
        #   abbr ls lsd
        #   abbr la "ls -alh"
        #
        # then I type `la` which expands into:
        #   ls -alh
        # and I run this...
        #   if I don't check for command/func shadowing then the stub func will be run b/c of my first abbr
        #   - this is 100% not what I want
        #   I am happy to settle on an abbr definition time check to avoid this, and warning to user
    fi

}

# shellcheck disable=SC2317 # sick of it complaining about unused options in while loop
abbr() {

    # compat layer, also this is where I'll accept --no-space-after
    # FORMAT
    #   key=value
    #   key=value --no-space-after
    #   PRN other options

    local set_cursor=""
    local no_space_after="no"
    local position=""
    local positional_args=()
    local func=""
    local regex=""
    local cmd=""

    # * fish abbr:
    # abbr --add NAME [--position command | anywhere] [-r | --regex PATTERN] [-c | --command COMMAND]
    #                 [--set-cursor[=MARKER]] ([-f | --function FUNCTION] | EXPANSION)
    # abbr --erase NAME ...
    # abbr --rename OLD_WORD NEW_WORD
    # abbr --show
    # abbr --list
    # abbr --query NAME ...

    # getopt SUCKS.. just use a while loop, it will work FINE
    #  ONE requirement will be to use an = to provide values for options...
    #  so I don't have to statefully parse options (yet)
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --set-cursor=*)
            set_cursor="${1#*=}" # strip (non-greedy) first matching part (through =)
            shift
            ;;
        --set-cursor)
            set_cursor="%" # uses default of %
            shift
            ;;
        --no-space-after)
            no_space_after="yes"
            shift
            ;;
        --position=*)
            position="${1#*=}"
            shift
            ;;
        --position)
            # required value is thus next arg => $2
            position="${2}"
            shift 2
            ;;
        --command)
            cmd="${2}"
            shift 2
            ;;
        --regex)
            regex="${2}"
            shift 2
            ;;
        --function)
            func="${2}"
            shift 2
            ;;
        -a)
            # ignore -a, it's a meaningless option from fish's abbr
            shift
            ;;
        --) # explicit end of options
            shift
            break # stop checking for options (rest are positional)
            ;;
        -*)
            echo "Unknown option: $1" >&2
            return 1
            ;;
        *)
            positional_args+=("$1") # scoop up non-option args to treat as positional later
            shift
            ;;
        esac
    done

    # treat remaining args as positional
    positional_args+=("$@")

    # echo "  set_cursor=$set_cursor"
    # echo "  no_space_after=$no_space_after"
    # echo "  position=$position"
    # echo "  positional args: ${positional_args[*]}"

    local key
    local value
    if ((${#positional_args[@]} == 1)); then
        local only_arg="${positional_args[0]}"
        if [[ "$only_arg" == *\=* ]]; then
            # if = is present then just parse both, it won't hurt scenarios where I don't need the value (i.e. --function)
            key="${only_arg%=*}"   # strip '=' thru end
            value="${only_arg#*=}" # strip prefix to '='
        elif [[ -n "$func" || -n "$regex" ]]; then
            # --function only needs key (not value) part
            # regex depends on --function too so --function s/b enough  of a check
            key="$only_arg"
            value=""
        fi
    elif ((${#positional_args[@]} == 2)); then
        key="${positional_args[0]}"
        value="${positional_args[1]}"
    else
        echo "unexpected positional args, should only be one (name=value) or two (name value)"
        echo "but got ${#positional_args[@]} args: ${positional_args[*]}"
        return 1
    fi
    _abbr "$key" "$value"

    if [[ "$no_space_after" = "yes" ]]; then
        abbrs_no_space_after["$key"]=yes
    fi
    if [[ "$position" = "anywhere" ]]; then
        abbrs_anywhere["$key"]=yes
    fi
    if [[ "$regex" ]]; then
        abbrs_regex["$key"]="$regex"
    fi
    if [[ "$set_cursor" ]]; then
        abbrs_set_cursor["$key"]="$set_cursor"
    fi
    if [[ "$func" ]]; then

        if [[ -n "$ABBR_DEBUG" ]]; then
            if ! declare -f "$func"; then
                echo "MISSING FUNCTION for abbr: $func"
            fi
        fi

        abbrs_function["$key"]="$func"
    fi
    if [[ "$cmd" ]]; then
        abbrs_command["$key"]="$cmd"
    fi

}

reset_abbrs() {
    if ((${#abbrs[@]} >= 10)); then
        # most tests have one abbr (maybe two?) ... so use 10 as a threshold to assume you ran tests in a real shell (after real abbrs loaded) and reset them and that's not wise to then use for real
        echo -e "${BOLD_RED} resetting ${#abbrs[@]} abbrs... restart shell after tests run, do not continue to use shell beyond test runs ${RESET}"
    fi

    abbrs=()
    abbrs_no_space_after=()
    abbrs_set_cursor=()
    abbrs_anywhere=()
    abbrs_function=()
    abbrs_command=()
    abbrs_regex=()

    # * clear stub functions (from tab completion)
    for name in "${abbrs_stub_func_names[@]}"; do
        local body=$(declare -f "$name")
        local must_contain="echo 'abbrs are not intended to be executed directly"
        if [[ "$body" == *"$must_contain"* ]]; then
            unset "$name"
        fi
    done
    abbrs_stub_func_names=()
}

test_parse_abbr_args() {

    if [[ -z "$ABBR_TESTS" ]]; then
        return
    fi

    # * tests --set-cursor
    start_test abbr foo=bar --set-cursor
    expect_equal "${abbrs[foo]}" "bar"
    expect_equal "${abbrs_set_cursor[foo]}" "%"
    expect_equal "${abbrs_no_space_after[foo]}" ""
    # * validate stub function created
    expect_function_exists foo "echo 'abbrs are not intended to be executed directly"
    expect_equal "${abbrs_stub_func_names[foo]}" "foo"

    start_test abbr --set-cursor hello=world
    expect_equal "${abbrs[hello]}" "world"
    expect_equal "${abbrs_set_cursor[hello]}" "%"

    # * test reset
    start_test reset_abbrs
    expect_equal "${abbrs[foo]}" ""
    expect_equal "${abbrs_set_cursor[foo]}" ""
    expect_equal "${abbrs[hello]}" ""
    expect_equal "${abbrs_set_cursor[hello]}" ""
    # ensure stub functions removed:
    expect_equal "${abbrs_stub_func_names[foo]}" ""
    expect_function_not_defined "foo"
    expect_equal "${abbrs_stub_func_names[hello]}" ""
    expect_function_not_defined "hello"

    # * --set-cursor=_
    start_test abbr foo='b_ar' --set-cursor='_'
    expect_equal "${abbrs[foo]}" "b_ar"
    expect_equal "${abbrs_set_cursor[foo]}" '_'
    expect_equal "${abbrs_no_space_after[foo]}" ""
    reset_abbrs

    # * tests --no-space-after
    start_test abbr foo=bar --no-space-after
    expect_equal "${abbrs[foo]}" "bar"
    expect_equal "${abbrs_no_space_after[foo]}" "yes"

    # * --no-space-after before positionals
    start_test abbr --no-space-after hello=world
    expect_equal "${abbrs[hello]}" "world"
    expect_equal "${abbrs_no_space_after[hello]}" "yes"

    # * test reset of no space after
    start_test reset_abbrs
    expect_equal "${abbrs_no_space_after[foo]}" ""
    expect_equal "${abbrs_no_space_after[hello]}" ""

    # * tests --position
    start_test abbr foo=bar --position=anywhere
    expect_equal "${abbrs[foo]}" "bar"
    expect_equal "${abbrs_anywhere[foo]}" "yes"

    # * test reset of abbrs_anywhere
    start_test reset_abbrs
    expect_equal "${abbrs_anywhere[foo]}" ""

    # * tests "position anywhere" where no = means it MUST have value in next word
    start_test abbr --position anywhere foo=bar
    expect_equal "${abbrs[foo]}" "bar"
    expect_equal "${abbrs_anywhere[foo]}" "yes"
    reset_abbrs

    # * -- w/ options before
    start_test abbr --position=anywhere -- hello=world
    expect_equal "${abbrs[hello]}" "world"
    expect_equal "${abbrs_anywhere[hello]}" "yes"
    reset_abbrs

    # * ONLY -- key=value (no options)
    start_test abbr -- hello=world
    expect_equal "${abbrs[hello]}" "world"
    reset_abbrs

    # * --function
    start_test abbr --function call_func -- func
    expect_equal "${abbrs[func]}" ""
    expect_equal "${abbrs_function[func]}" "call_func"

    # ensure clears abbrs_function
    start_test reset_abbrs
    expect_equal "${abbrs_function[func]}" ""

    # * --regex / --function COMBO
    start_test abbr --function call_func --regex "gl\d" -- func
    expect_equal "${abbrs[func]}" ""
    expect_equal "${abbrs_function[func]}" "call_func"
    expect_equal "${abbrs_regex[func]}" "gl\d"

    # ensure clears abbrs_regex
    start_test reset_abbrs
    expect_equal "${abbrs_regex[func]}" ""

    # * --command
    start_test abbr --command only_this_cmd -- cmd only
    expect_equal "${abbrs[cmd]}" "only"
    expect_equal "${abbrs_command[cmd]}" "only_this_cmd"

    # ensure clears abbrs_command
    start_test reset_abbrs
    expect_equal "${abbrs_command[cmd]}" ""

    # exit when testing completes, that way you can easily run bash again to test again
    # exit
}
test_parse_abbr_args

test_expand_abbr() {

    if [[ -z "$ABBR_TESTS" ]]; then
        return
    fi

    label_test "vanilla abbr"
    reset_abbrs
    abbr foo bar
    READLINE_LINE=foo
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "bar "
    expect_equal "$READLINE_POINT" 4

    label_test "vanilla w/ --no-space-after"
    reset_abbrs
    abbr foo bar --no-space-after
    READLINE_LINE=foo
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "bar"
    expect_equal "$READLINE_POINT" 3

    label_test "--set-cursor"
    reset_abbrs
    abbr foo "echo '%'" --set-cursor
    READLINE_LINE=foo
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "echo '' "
    expect_equal "$READLINE_POINT" 6

    label_test "--set-cursor='_'"
    reset_abbrs
    abbr foo "echo '_'" --set-cursor='_'
    READLINE_LINE=foo
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "echo '' "
    expect_equal "$READLINE_POINT" 6

    label_test "--no-space-after + --set-cursor"
    reset_abbrs
    abbr foo "echo '%'" --set-cursor --no-space-after
    READLINE_LINE=foo
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "echo ''"
    expect_equal "$READLINE_POINT" 6

    label_test "space still works when not an abbr"
    reset_abbrs
    READLINE_LINE=foo
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "foo "
    expect_equal "$READLINE_POINT" 4

    label_test "current command does not match '--command limited'"
    reset_abbrs
    abbr foo bar --command limited
    READLINE_LINE="other foo"
    READLINE_POINT=9
    expand_abbr " "
    expect_equal "$READLINE_LINE" "other foo "
    expect_equal "$READLINE_POINT" 10

    label_test "current command matches '--command limited'"
    reset_abbrs
    abbr foo bar --command limited
    READLINE_LINE="limited foo"
    READLINE_POINT=11
    expand_abbr " "
    expect_equal "$READLINE_LINE" "limited bar "
    expect_equal "$READLINE_POINT" 12

    label_test "position not set - works in command position"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "bar "
    expect_equal "$READLINE_POINT" 4

    label_test "position not set - DOES NOT work in NON command position"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="cmd foo"
    READLINE_POINT=7
    expand_abbr " "
    expect_equal "$READLINE_LINE" "cmd foo "
    expect_equal "$READLINE_POINT" 8

    label_test "--position=anywhere - works in command position"
    reset_abbrs
    abbr foo bar --position=anywhere
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "bar "
    expect_equal "$READLINE_POINT" 4

    label_test "--position=anywhere - works in NON command position"
    reset_abbrs
    abbr foo bar --position=anywhere
    READLINE_LINE="cmd foo"
    READLINE_POINT=7
    expand_abbr " "
    expect_equal "$READLINE_LINE" "cmd bar "
    expect_equal "$READLINE_POINT" 8

    # * --function
    label_test "--function hello - expands to result of function"
    reset_abbrs
    function hello { echo world; }
    abbr foo --function hello # only need abbr name (not value)
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "world "
    expect_equal "$READLINE_POINT" 6

    # * --regex
    label_test "regex: abbr name matches but regex does not, AND should not just invoke function without testing regex first"
    reset_abbrs
    function expand_for_regex { echo reggy; }
    abbr foo --function expand_for_regex --regex patty
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "foo " # this would have to be patty and its foo, don't match on name for regex abbrs!
    expect_equal "$READLINE_POINT" 4

    # # TODO perf wise if it matters, I could add --non-regex-prefix for the part that matches verbatim to speed up initial comparisons before apply regex check for all regex abbrs (on every word typed)
    label_test "regex: match on regex (but not name)"
    reset_abbrs
    function expand_for_regex { echo reggy; }
    abbr foo --function expand_for_regex --regex patty
    READLINE_LINE="patty"
    READLINE_POINT=5
    expand_abbr " "
    expect_equal "$READLINE_LINE" "reggy "
    expect_equal "$READLINE_POINT" 6

    label_test "regex: match on regex with digit wildcard"
    reset_abbrs
    function expand_for_regex { echo patty "$1"; }
    abbr foo --function expand_for_regex --regex pat[0-9]+
    READLINE_LINE="pat10"
    READLINE_POINT=5
    expand_abbr " "
    expect_equal "$READLINE_LINE" "patty pat10 "
    expect_equal "$READLINE_POINT" 12

    # * middle of commandline (command position, abbr)
    label_test "middle of commandline: on abbr in command position"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo the car"
    READLINE_POINT=3 # cursor after foo, not end of line
    expand_abbr " "
    expect_equal "$READLINE_LINE" "bar  the car" # YES it adds a space too, so there are two... that is 100% expected
    expect_equal "$READLINE_POINT" 4

    # * middle of commandline (command position, abbr, BUT not at end of abbr => adds space)
    label_test "middle of commandline: on abbr in command position, but NOT at end of abbr: adds space only"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo the car"
    READLINE_POINT=2 # cursor after `fo` which is not full abbr text
    expand_abbr " "
    expect_equal "$READLINE_LINE" "fo o the car"
    expect_equal "$READLINE_POINT" 3

    # * middle of commandline
    label_test "middle of commandline: not on abbr, adds space only"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo the car"
    READLINE_POINT=7 # cursor after the
    expand_abbr " "
    expect_equal "$READLINE_LINE" "foo the  car" # ONLY adds space!
    expect_equal "$READLINE_POINT" 8

    # * ; semicolon trigger tests
    label_test "semicolon trigger instead of space"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr ";"
    expect_equal "$READLINE_LINE" "bar;"
    expect_equal "$READLINE_POINT" 4

    # * | pipeline trigger tests
    label_test "pipeline trigger instead of space"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr "|"
    expect_equal "$READLINE_LINE" "bar|"
    expect_equal "$READLINE_POINT" 4

    # *** regression - no expansion => inserts typed character (i.e. pipe)
    label_test "no expansion => inserts | pipe"
    reset_abbrs
    abbr other other
    READLINE_LINE="echo foo "
    READLINE_POINT=9
    expand_abbr "|"
    expect_equal "$READLINE_LINE" "echo foo |"
    expect_equal "$READLINE_POINT" 10

    # *** multi-command commandline tests
    label_test "should expand command position after a pipe"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="echo hello | foo"
    READLINE_POINT=16
    expand_abbr " "
    expect_equal "$READLINE_LINE" "echo hello | bar "
    expect_equal "$READLINE_POINT" 17

    # TODO assume separators for pipelines/lists indicate next word is in command position
    # simple command is what I have now:
    #   gst<SPACE> => git status
    # pipelines (| or |& separator, sequence of commands)
    #   command1 | command2
    # lists (sequence of pipelines - ; & && or ||)
    #   command1; command2; cmda | cmdb; command_n
    # compound commands
    #   ( list ) # subshell
    #   { list; } # group command
    #   (( arithmetic_expr ))
    #   [[ conditional_expr ]]
    #
    # ultimately it would be nice to have a parser that can tokenize and identify command positions for me

}
test_expand_abbr
