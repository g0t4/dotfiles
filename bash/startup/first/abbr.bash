source _test.bash 2>/dev/null || true # ignore load failure, source is for bash LS (i.e. F12) and shellcheck

declare -A abbrs=()
declare -A abbrs_set_cursor=()
declare -A abbrs_anywhere=()
declare -A abbrs_function=()
declare -A abbrs_regex=()
declare -A abbrs_command=()
declare -A abbrs_stub_func_names=()

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
    ['(']='(' ['{']='{'     # openings that should denote start of command afterward
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
    _dump_var check_if_this_is_a_cmd_separator
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
    local add_char_if_no_expansion="$key"
    if [[ "$key" = "tab_space_regardless" ]]; then
        add_char=" "
        add_char_if_no_expansion=" "
    fi
    if [[ "$key" = "tab_space_if_expand_only" ]]; then
        add_char=" "
        add_char_if_no_expansion=""
    fi
    if [[ "$key" = "enter" ]]; then
        # for enter we have the \C-j in the bind macro, not doing that here
        add_char=""
        add_char_if_no_expansion=""
    fi

    local anywhere="no"
    if is_anywhere_allowed "$word_before_cursor"; then
        anywhere="yes"
    fi

    local allowed_position="no"
    local tmp_prefix_for_previous_word="${READLINE_LINE:0:$word_before_start_offset}"
    local previous_word=$(echo "$tmp_prefix_for_previous_word" | awk '{print $NF}')
    local check_if_this_is_a_cmd_separator="$previous_word"
    if [[ "$check_if_this_is_a_cmd_separator" == *\; ]]; then
        # TODO what other chars should be the same?
        # if ends in semicolon, treat command separator lookup as semicolon
        # NOTE some separators must be standalone words
        # PRN should I build regex in command_separators array and just check all of them?
        check_if_this_is_a_cmd_separator=";"
    fi
    if [[ $word_before_start_offset -eq 0 || ${command_separators["$check_if_this_is_a_cmd_separator"]} || "$anywhere" = "yes" ]]; then
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

_setup_intercepts_for_rest_of_keys() {
    # * expand on <Space>
    bind -x '" ": expand_abbr " "'
    bind -x '";": expand_abbr ";"' # so you can:   gst<;> => git status;
    bind -x '"|": expand_abbr "|"' # same as ;
    bind -m vi-insert -x '" ": expand_abbr " "'
    bind -m vi-insert -x '";": expand_abbr ";"'
    bind -m vi-insert -x '"|": expand_abbr "|"'
    # TODO intercept tab and expand on tab complete too (else right now you have to backup (backspace) and then hit space again)
}
_setup_intercepts_for_rest_of_keys

_setup_intercept_for_enter() {
    # Steps
    # 1. intercept Enter
    # 2. (attempt) abbr-expand
    # 3. accept-line

    key_seq_expand_abbr_enter='\C-x\C-['
    #
    # key_seq_accept_line='\C-x\C-]' # if I want my own key seq again for accept-line
    key_seq_accept_line='\C-j' # OOB accept-line bound to BOTH \C-j & \C-m, so I don't need another virtual key seq
    #
    # emacs keymap:
    bind -m emacs "\"\C-m\": \"$key_seq_expand_abbr_enter$key_seq_accept_line\"" # * intercept Enter (Ctrl-M)
    bind -m emacs -x "\"$key_seq_expand_abbr_enter\": expand_abbr enter"
    bind -m emacs "\"$key_seq_accept_line\": accept-line" # redundant if using \C-j, uncomment if change key seq
    #
    # vi-insert keymap:
    bind -m vi-insert "\"\C-m\": \"$key_seq_expand_abbr_enter$key_seq_accept_line\"" # * intercept Enter (Ctrl-M)
    bind -m vi-insert -x "\"$key_seq_expand_abbr_enter\": expand_abbr enter"
    bind -m vi-insert "\"$key_seq_accept_line\": accept-line" # redundant if using \C-j, uncomment if change key seq
}
_setup_intercept_for_enter

__expand_abbr_tab() {
    # PRN I might have to call and capture the CMDLINE before complete and after (here) and compare to decide if complete happened or not
    #   ** can put another bash func ahead of complete to capture READLINE_LINE and READLINE_POINT and then compare them here

    #  for now assume space means completion accepted
    local char_before_index
    ((char_before_index = READLINE_POINT - 1))
    if ((char_before_index < 0)); then
        # bail b/c at start of line... nothing to complete
        # echo nothing to expand at start of line
        return
    fi
    local char_before_cursor="${READLINE_LINE:$char_before_index:1}"
    # declare -p char_before_index char_before_cursor READLINE_LINE READLINE_POINT | bat -l bash
    if [[ "$char_before_cursor" == " " ]]; then
        # ? use regex ^\s$
        # remove space (without destroying rest of cmdline)
        # TODO add tests of this using my test fwk
        READLINE_LINE="${READLINE_LINE:0:$char_before_index}${READLINE_LINE:$READLINE_POINT}"
        ((READLINE_POINT = READLINE_POINT - 1))
        # declare -p READLINE_LINE READLINE_POINT
        expand_abbr tab_space_regardless
        # TODO two tests: one on expand, one on not expand (test spacing results on both)
    else
        # then call regular expand_abbr
        expand_abbr tab_space_if_expand_only
        # TODO tests that handle adding space on expand, another that does not on not expand
    fi
    # echo "------------"
}

_setup_intercept_for_tab() {

    # STEPS:
    # 1. intercept tab
    # 2. call complete
    #   - if completed, remove space
    # 3. attempt abbr-expand
    #   - if expanded => add space
    #   - else no space so user can further modify and/or tab complete
    #
    # FYI Ctrl-x,Ctrl-* shortcuts are mostly unused in emacs/vi-insert modes
    #    IOTW use this as a "namespace" of key sequences for my automations
    #    bind -m emacs -p | grep -i "C-x\\\C"
    #
    key_seq_expand_abbr_tab='\C-x\C-t'
    #
    key_seq_complete='\C-x\C-i' # need new key seq b/c I am going to intercept \C-i
    #
    # emacs keymap:
    bind -m emacs "\"\C-i\": \"$key_seq_complete$key_seq_expand_abbr_tab\"" # * intercept Tab (Ctrl-i)
    bind -m emacs "\"$key_seq_complete\": complete"
    bind -m emacs -x "\"$key_seq_expand_abbr_tab\": __expand_abbr_tab"
    #
    # vi-insert keymap:
    # bind -m vi-insert "\"\C-i\": \"$key_seq_expand_abbr_tab\"" # * intercept Tab (Ctrl-i) TESTING: only call expand_abbr_tab (no complete first)
    bind -m vi-insert "\"\C-i\": \"$key_seq_complete$key_seq_expand_abbr_tab\"" # * intercept Tab (Ctrl-i)
    bind -m vi-insert "\"$key_seq_complete\": complete"
    bind -m vi-insert -x "\"$key_seq_expand_abbr_tab\": __expand_abbr_tab"
    # tests:
    # - tab completes an abbr
    #   bind_show<TAB>  # unique prefix so it tab completes right away => should expand out the abbr too!
    # - tab completes a NON abbr
    #   whi<TAB> # should leave tab there and show completions only...
    #     TODO broken ... inserts a space... ugh
    # - tab after a completed abbr:
    #   gst <CURSOR><TAB>bar # should expand into `git status bar`
    #
}
_setup_intercept_for_tab

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

colorful() {
    # TLDR pipe STDOUT to this function so STDIN here is mapped into one of two commands in a subshell:
    if is_stdout_a_terminal && command_exists bat; then
        bat -l "$1"
    else
        cat
    fi
}

list_abbrs() {
    _list_abbrs | colorful bash
}

_print_abbr_definition() {
    local name="$1"
    local set_cursor value regex func cmd_only anywhere
    value="${abbrs[$name]}"
    set_cursor="${abbrs_set_cursor[$name]}"
    regex="${abbrs_regex[$name]}"
    func="${abbrs_function[$name]}"
    cmd_only="${abbrs_command[$name]}"
    anywhere="${abbrs_anywhere[$name]}"
    local -a opts=()
    if [[ -n "$set_cursor" ]]; then
        opts+=("--set-cursor=$set_cursor")
    fi
    if [[ -n "$regex" ]]; then
        # TODO do I like how printf is working, is it slow? fast? I can always escape things myself too, just wanted to try this
        quoted_regex=$(printf "%q" "$regex")
        # printf will return escaped chars for double quoted string
        # still need to add "" though and to expand the quoted var requires "" so... just yeah:
        opts+=("--regex" "\"$quoted_regex\"")
    fi
    if [[ -n "${func}" ]]; then
        opts+=("--function" "$func")
    fi
    if [[ -n "${cmd_only}" ]]; then
        opts+=("--command" "$cmd_only")
    fi
    if [[ -n "${anywhere}" ]]; then
        opts+=("--position" "anywhere")
    fi

    # TODO if value has ' single quote, then cannot use ' to surround value... printf or?
    # in that case use double quotes and escape special chars like $ ! \ " and newline
    # FYI some values are empty b/c they are regex+function
    echo abbr -a "${opts[*]}" -- "$name" "'$value'"
}

_list_abbrs() {
    local name
    for name in "${!abbrs[@]}"; do
        _print_abbr_definition "$name"
    done
}

# shellcheck disable=SC2317 # sick of it complaining about unused options in while loop
abbr() {
    # if called with no args, list abbrs like fish shell
    if (($# == 0)); then
        list_abbrs
        return
    fi

    local set_cursor=""
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
            -a | --add)
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

    # * test -a (basically ignore this)
    start_test abbr -a uses "dash_a"
    expect_equal "${abbrs[uses]}" "dash_a"
    reset_abbrs

    # * test --add (basically ignore this)
    start_test abbr --add uses "dash_dash_add"
    expect_equal "${abbrs[uses]}" "dash_dash_add"
    reset_abbrs

    # * --set-cursor=_
    start_test abbr foo='b_ar' --set-cursor='_'
    expect_equal "${abbrs[foo]}" "b_ar"
    expect_equal "${abbrs_set_cursor[foo]}" '_'
    reset_abbrs

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
    expand_abbr " " # akin to typing SPACE
    expect_equal "$READLINE_LINE" "bar "
    expect_equal "$READLINE_POINT" 4

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
    label_test "--function hello_dash_dash_function_test - expands to result of function"
    reset_abbrs
    function hello_dash_dash_function_test { echo world; }
    abbr foo --function hello_dash_dash_function_test # only need abbr name (not value)
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

    # * user types ; semicolon which triggers abbr
    label_test "semicolon trigger instead of space"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr ";"
    expect_equal "$READLINE_LINE" "bar;"
    expect_equal "$READLINE_POINT" 4

    # * user types ; semicolon which triggers abbr
    label_test "semicolon trigger instead of space"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr ";"
    expect_equal "$READLINE_LINE" "bar;"
    expect_equal "$READLINE_POINT" 4

    # * user types | in a pipeline which triggers abbr
    label_test "pipeline trigger instead of space"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr "|"
    expect_equal "$READLINE_LINE" "bar|"
    expect_equal "$READLINE_POINT" 4

    # *** regression - no expansion => inserts typed character (i.e. pipe, but applies to others too)
    label_test "no expansion => inserts | pipe"
    reset_abbrs
    abbr other other
    READLINE_LINE="echo foo "
    READLINE_POINT=9
    expand_abbr "|" # PRN parameterize this?
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

    label_test "should expand command position after a standalone ; semicolon word"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="echo hello ; foo"
    READLINE_POINT=16
    expand_abbr " "
    expect_equal "$READLINE_LINE" "echo hello ; bar "
    expect_equal "$READLINE_POINT" 17

    label_test "should expand command position after a ; on end of word"
    reset_abbrs
    abbr foo bar
    READLINE_LINE="echo hello; foo"
    READLINE_POINT=15
    expand_abbr " "
    expect_equal "$READLINE_LINE" "echo hello; bar "
    expect_equal "$READLINE_POINT" 16

    label_test "should expand command position after a standalone ( subshell opener"
    reset_abbrs
    abbr foo1 bar1
    READLINE_LINE="echo hello ( foo1"
    READLINE_POINT=17
    expand_abbr " "
    expect_equal "$READLINE_LINE" "echo hello ( bar1 "
    expect_equal "$READLINE_POINT" 18

    label_test "should expand command position after a ( on start of word"
    reset_abbrs
    abbr foo2 bar2
    READLINE_LINE="echo hello (foo2"
    READLINE_POINT=16
    expand_abbr " "
    expect_equal "$READLINE_LINE" "echo hello (bar2 "
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

# shellcheck disable=SC2155 # don't care about local define and assign together
function generate_func_wrappers {
    local func_file="${BASH_DOTFILES}/.generated.fish_func_wrappers.bash"
    echo >"$func_file" # reset file

    # * abbr functions
    local name
    for name in "${!abbrs_function[@]}"; do
        local func_name="${abbrs_function[$name]}"
        local definition="$(_print_abbr_definition "$name")"

        if [[ "$1" == *\"* ]]; then
            # FYI I had to quote the \"$1\" below for expand_zsh_equals which was triggering on typing this: "(IFS=,;" FTR
            # TODO add tests of the generated wrappers so I know if I broke any edge cases - start with expand_zsh_equals
            echo "ALERT - generate_func_wrappers doesn't yet escape \" and just found one in your cmdline to expand"
        fi
        cat <<EOF >>"$func_file"

function $func_name {
    # $definition
    # $name
    fish -c "$func_name \"\$1\""
}

EOF
    done

    # * non-abbr functions

    ignore_functions=(
        # TODO manual ports: (mark when done)
        cd_dir_of_path    # does a cd... needs manual wrapper
        cd_dir_of_command # manual

        #FISH ONLY:
        fish_update_completions
    )
    # TODO MOVE back to inside generate above once done with initial review:
    non_abbr_functions=(
        git_unpushed_commits
        bitmaths
        touchp
        gitignores_for # lol this is a zsh wrapped fish func ;) bash => fish => zsh
        wordcount
        md_open
        ffplay
        cppath
        commit_gitignores_for
        append_gitignores_for
        gitignore_init
        # icdiff ??? basically alias for icdiff options
        # ffmpeg ??? basically ffmpeg alias
        # ffprobe ??? alias
        #
        # TODO check if ok:
        # gh_repo_create_public
        # __gh_repo_create_clone_with_ignores # ??
        # gh_repo_create_private # might have cd

    )

    for func_name in "${non_abbr_functions[@]}"; do

        # Example of wrapped function w/ args that can't be passed w/o quoting:
        #    `touch "foo the"` => create a file w/ a space in the name
        #    also ffmpeg/ffplay to play a file w/ space would be broken

        # block expansion with 'EOF_WRAPPER' b/c its easier to use find replace than quote all the $ in the template!
        wrapper_template=$(
            cat <<'EOF_WRAPPER'
function PLACEHOLDER_FUNC_NAME {
  fish_args=""
  for arg in "$@"; do
    printf -v escaped_arg '%q' "$arg" # quote arg: "foo the bar" => foo\ the\ bar
    fish_args+=" $escaped_arg"
  done

  fish -c "PLACEHOLDER_FUNC_NAME $fish_args"
}
EOF_WRAPPER
        )

        generated_wrapper="${wrapper_template//PLACEHOLDER_FUNC_NAME/$func_name}"

        echo "$generated_wrapper" >>"$func_file"

    done

    # shellcheck disable=SC2317
    function look_for_non_abbr_functions {

        mapfile -t fish_function_names <<<"$(fish -c "functions")"
        # declare -p fish_function_names | bat -l bash

        # BUILDING associative arrays for simplified code below:
        declare -A fish_funcs_hash=()
        for n in "${fish_function_names[@]}"; do
            fish_funcs_hash["$n"]="$n"
        done
        declare -A already_identified_hash=()
        for n in "${non_abbr_functions[@]}"; do
            already_identified_hash["$n"]="$n"
        done
        declare -A ignore_functions_hash=()
        for n in "${ignore_functions[@]}"; do
            ignore_functions_hash["$n"]="$n"
        done

        local abbr_name
        for abbr_name in "${!abbrs[@]}"; do
            local abbr_value="${abbrs["$abbr_name"]}"
            if [[ -z "$abbr_value" ]]; then
                # echo "empty value '$abbr_value' from abbr: '$abbr_name'"
                continue
            fi
            if [[ -n "${fish_funcs_hash["$abbr_value"]}" ]]; then
                if [[ -n "${ignore_functions_hash["$abbr_value"]}" ]]; then
                    # echo "ignored function: '$abbr_value' from abbr: '$abbr_name'"
                    continue
                fi
                if [[ -n "${already_identified_hash["$abbr_value"]}" ]]; then
                    # echo "already function: '$abbr_value' from abbr: '$abbr_name'"
                    continue
                fi

                echo "possible function: '$abbr_value' from abbr: '$abbr_name'"
                # show fish func:
                fish -c "functions $abbr_value"
                echo
            fi
        done

    }
    # look_for_non_abbr_functions

}
