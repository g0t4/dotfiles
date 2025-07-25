source _test.bash 2>/dev/null || true # ignore load failure, source is for bash LS (i.e. F12) and shellcheck

declare -A abbrs=()
declare -A abbrs_no_space_after=()
declare -A abbrs_set_cursor=()
declare -A abbrs_anywhere=()
declare -A abbrs_function=()
declare -A abbrs_command=()

is_no_space_after_set() {
    local word="$1"
    [[ -n "$word" && "${abbrs_no_space_after["$word"]}" = "yes" ]]
}

is_anywhere_allowed() {
    local word="$1"
    [[ -n "$word" && "${abbrs_anywhere["$word"]}" = "yes" ]]
}

expand_abbr() {
    local key="$1"
    # echo "READLINE_LINE: $READLINE_LINE"
    # echo "READLINE_POINT: $READLINE_POINT"

    # * pseudo-tokenize (prefix / word_before_cursor / cursor / suffix)
    local line_before_cursor="${READLINE_LINE:0:READLINE_POINT}"
    local word_before_cursor="${line_before_cursor##* }"
    local word_start_offset=$((READLINE_POINT - ${#word_before_cursor}))
    local prefix="${READLINE_LINE:0:word_start_offset}"
    local suffix="${READLINE_LINE:READLINE_POINT}"

    local expanded=""
    if [[ "$word_before_cursor" != "" ]]; then
        expanded="${abbrs[$word_before_cursor]}"
        # PRN for --function would require the function to exist in bash (manually migrate)
        #   so probably just migrate those abbrs by hand anyways?
        #   then... get func name out and eval "$func_name $READLINE_LINE" or READLINE_LINE would already be in scope anyways so don't pass it
    fi

    # * add_char
    local add_char="$key"
    local no_expand_add_char=" " # -no-space-after does not apply if no expansion
    if [[ "$key" = "enter" ]]; then
        # for enter we have the \C-j in the bind macro, not doing that here
        add_char=""
        no_expand_add_char=""
    fi
    if is_no_space_after_set "$word_before_cursor"; then
        add_char=""
    fi

    # echo "word_before_cursor: _${word_before_cursor}_"
    # echo "add_char: _${add_char}_"

    local anywhere="no"
    if is_anywhere_allowed "$word_before_cursor"; then
        anywhere="yes"
    fi

    local allowed_position="no"
    if [[ $word_start_offset -eq 0 || "$anywhere" = "yes" ]]; then
        allowed_position=yes
        # TODO pipelines
        # TODO lists (sequential commands - check position relative to current 'simple command')...
        #  need something that can tokenize the line... for now these will just work in simple commands only which is 90% of what I want anyways
    fi

    lookup_only_cmd() {
        local word="$1"
        if [[ -z "$word" ]]; then
            # key lookup fails if word is empty
            echo ""
        fi
        echo "${abbrs_command["$word"]}"
    }

    # shellcheck disable=SC2155
    local only_cmd=$(lookup_only_cmd "$word_before_cursor")
    if [[ -n "$only_cmd" ]]; then
        #  cmd (at start of line) matches --command... use this to set allowed_position (override other checks above)
        # TODO consider pipelines / lists for what is current command (vs just simple command)
        first_word="${READLINE_LINE%% *}" # greedy strip end of line until first space in line => thus first command
        if [[ "$only_cmd" = "$first_word" ]]; then
            allowed_position=yes
        else
            allowed_position=no
        fi
        # echo "READLINE_LINE: $READLINE_LINE" # leave as reminder, echo prints above prompt, great for troubleshooting!
        # echo "first_word: $first_word"
        # return
    fi

    if [[ "$expanded" = "" || "$allowed_position" = "no" ]]; then
        # no expansion => insert char and return early
        READLINE_LINE="${prefix}${word_before_cursor}${no_expand_add_char}${suffix}"
        READLINE_POINT=$((${#prefix} + ${#word_before_cursor} + ${#no_expand_add_char}))
        return 0
    fi

    # * inject expansion and move cursor
    local set_cursor="${abbrs_set_cursor["$word_before_cursor"]}"
    if [[ $set_cursor ]]; then
        # * --set-cursor

        # locate set_cursor char (i.e. %) in the expanded text
        local expand_char="$set_cursor"
        local before_cursor="${expanded%%"${expand_char}"*}" # everything before %
        local after_cursor="${expanded#*"${expand_char}"}"   # everything after %
        # effectively strips the % char (b/c its the cursor marker)
        # PRN map diff char than % ONLY IF issues with %... i.e. would mean I need an abbr that has % in the expanded text AND --set-cursor at same time

        READLINE_LINE="${prefix}${before_cursor}${after_cursor}${add_char}${suffix}"
        READLINE_POINT=$((${#before_cursor} + ${#prefix}))
    else
        # * cursor moves after expanded/add_char

        echo "#prefix: ${#prefix} '${prefix}'"
        echo "#expanded: ${#expanded} '${expanded}'"
        echo "#add_char: ${#add_char} '${add_char}'"

        READLINE_LINE="${prefix}${expanded}${add_char}${suffix}"
        # move cursor right AFTER add_char (so if in middle of line, won't go to end)
        READLINE_POINT=$((${#prefix} + ${#expanded} + ${#add_char}))
    fi

}
# * expand on <Space>
bind -x '" ": expand_abbr " "'
# bind -x '";": expand_abbr ";"' # TODO add test first # gst; should expand

# * expand on <Return>
expand_hack='\C-x\C-['
# acceptline_hack='\C-x\C-]'
acceptline_hack='\C-j' # OOB accept-line
bind -x "\"$expand_hack\": expand_abbr enter"
bind "\"$acceptline_hack\": accept-line"          # bind -p # lists readline actions
bind "\"\C-m\": \"$expand_hack$acceptline_hack\"" # bind -s # lists macro actions

command_exists() {
    command -v "$1" 1>/dev/null
}

_abbr() {
    # PRN handle options (if any) when I add abbrs that use them
    # PRN do I need to slice all remaining args?
    abbrs["${1}"]="${2}"

    # if a command/func exists, don't shadow it, the whole point of an abbr is to alter what is _typed_
    # - thankfully tab completion works fine if it already exists as a command/func!
    # if a command/func doesn't exist, then we need a stub func (or smth else) to get tab completion
    if ! command_exists "$1"; then

        # define function for tab completion
        # - i.e. g<TAB> includes abbrs starting with g!
        # eval "function ${1} { exec_abbr '${1}' \"\$@\"; }" # old design with fallback execution of abbr... would be ok to use again if I really find myself needing this
        eval "function ${1} { echo 'abbrs are not intended to be executed directly (i.e. if you disable abbr expansion)... if you think this is masking a real command, restart your shell to re-create abbrs and this warning will go away'; }"

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
        --function)
            func="${2}"
            shift 2
            ;;
        -a)
            # ignore -a, it's a meaningless option from fish's abbr
            shift
            ;;
        -g)
            # TODO remove -g support?
            position="anywhere"
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
        key="${positional_args%=*}"   # strip '=' thru end
        value="${positional_args#*=}" # strip prefix to '='
    elif ((${#positional_args[@]} == 2)); then
        key="${positional_args[0]}"
        value="${positional_args[1]}"
    else
        echo "unexpected positional args, should only be one (name=value) or two (name value)"
        echo "but got ${#positional_args[@]} args: ${positional_args[*]}"
        return 1
    fi
    # echo "  key: $key"
    # echo "  value: $value"
    _abbr "$key" "$value"

    # FYI check with:
    #     declare -p abbrs_no_space_after

    if [[ "$no_space_after" = "yes" ]]; then
        abbrs_no_space_after["$key"]=yes
    fi
    if [[ "$position" = "anywhere" ]]; then
        abbrs_anywhere["$key"]=yes
    fi
    if [[ "$set_cursor" ]]; then
        # FYI for now we will only work with % (fish default) that way I don't have to parse that here too
        abbrs_set_cursor["$key"]="$set_cursor"
    fi
    if [[ "$func" ]]; then
        # TODO use --function, currently ONLY parsing it
        abbrs_function["$key"]="$func"
    fi
    if [[ "$cmd" ]]; then
        abbrs_command["$key"]="$cmd"
    fi

}

reset_abbrs() {
    abbrs=()
    abbrs_no_space_after=()
    abbrs_set_cursor=()
    abbrs_anywhere=()
    abbrs_function=()
    abbrs_command=()
}

test_parse_abbr_args() {

    # * tests --set-cursor
    start_test abbr foo=bar --set-cursor
    expect_equal "${abbrs[foo]}" "bar"
    expect_equal "${abbrs_set_cursor[foo]}" "%"
    expect_equal "${abbrs_no_space_after[foo]}" ""

    start_test abbr --set-cursor hello=world
    expect_equal "${abbrs[hello]}" "world"
    expect_equal "${abbrs_set_cursor[hello]}" "%"

    # * test reset
    start_test reset_abbrs
    expect_equal "${abbrs[foo]}" ""
    expect_equal "${abbrs_set_cursor[foo]}" ""
    expect_equal "${abbrs[hello]}" ""
    expect_equal "${abbrs_set_cursor[hello]}" ""

    # * tests --no-space-after
    start_test abbr foo=bar --no-space-after
    expect_equal "${abbrs[foo]}" "bar"
    expect_equal "${abbrs_no_space_after[foo]}" "yes"

    start_test abbr --no-space-after hello=world
    expect_equal "${abbrs[hello]}" "world"
    expect_equal "${abbrs_no_space_after[hello]}" "yes"

    start_test reset_abbrs
    expect_equal "${abbrs_no_space_after[foo]}" ""
    expect_equal "${abbrs_no_space_after[hello]}" ""

    # * tests --position
    start_test abbr foo=bar --position=anywhere
    expect_equal "${abbrs[foo]}" "bar"
    expect_equal "${abbrs_anywhere[foo]}" "yes"

    start_test reset_abbrs
    expect_equal "${abbrs_anywhere[foo]}" ""

    # * tests "position anywhere" where no = means it MUST have value in next word
    start_test abbr --position anywhere foo=bar
    expect_equal "${abbrs[foo]}" "bar"
    expect_equal "${abbrs_anywhere[foo]}" "yes"
    reset_abbrs

    # * tests -g works too
    start_test abbr hello=world -g
    expect_equal "${abbrs[hello]}" "world"
    expect_equal "${abbrs_anywhere[hello]}" "yes"
    reset_abbrs

    # * tests -- works
    start_test abbr -g -- hello=world
    expect_equal "${abbrs[hello]}" "world"
    expect_equal "${abbrs_anywhere[hello]}" "yes"
    reset_abbrs

    start_test abbr -- hello=world # * no options, just -- and positional
    expect_equal "${abbrs[hello]}" "world"
    reset_abbrs

    # * --function
    start_test abbr --function call_func -- func ify
    expect_equal "${abbrs[func]}" "ify"
    expect_equal "${abbrs_function[func]}" "call_func"

    # ensure clears abbrs_function
    start_test reset_abbrs
    expect_equal "${abbrs_function[func]}" ""

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
# test_parse_abbr_args

test_expand_abbr() {

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

    label_test "--function=hello - expands to result of function"
    reset_abbrs
    abbr foo bar --function=hello
    READLINE_LINE="foo"
    READLINE_POINT=3
    expand_abbr " "
    expect_equal "$READLINE_LINE" "cmd hello "
    expect_equal "$READLINE_POINT" 10

    # PRN intercept ; too so `gst;` expands, else just insert ;

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
