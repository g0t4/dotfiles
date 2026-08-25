#
# FYI!!! some of these need to always be available (i.e. rag_indexer for use in git hooks)
#  and for simplicity, just load entire file always
#  PRN later I can split into two parts and put `if not status is-interactive` check to then `return` if there are parts that break non-interactive shell instances

set ASK_REPO "$HOME/repos/github/g0t4/ask-openai.nvim"

function ask_rewrite_diff_reviewer
    if set -q argv[1]
        set trace_file $argv[1]
    else
        set trace_file "*-trace.json"
    end
    # PRN pass trace file
    # use this to diff a trace.json file, to grab the response_message's content and diff that vs the original selection in the last user message(request_body.messages[-1].content)
    #  the bulk of the input and output are likely the selected code to rewrite, especially for large selections...
    #  also shows user request too
    #  model wise the model should only return rewritten code so it shouldn't have anything extra, unless it derps up markdown w/ explanations of its changes
    diff_two_commands "jq .request_body.messages[-1].content -r $trace_file" "jq .response_message.content -r $trace_file"
end

abbr --add abbr_trace_nth_file --regex 't\d*a?' --function abbr_expand_trace_nth_file
function abbr_expand_trace_nth_file --argument-names abbreviation
    set current_command_line (commandline)
    set current_cursor_position (commandline --cursor)
    set text_after_cursor (string sub --start (math $current_cursor_position + 1) $current_command_line)

    if test -n "$text_after_cursor"
        # AFAICT I cannot modify commandline (either blocked in abbrs OR when abbr is triggered fish snapshots commandline and then the expansion is inserted in the expanded word and the rest remains the same)
        # SO, don't close the quoted command... I'll have to do that myself
        # TODO can I schedule something to run after the abbr expands :)... if so I could end the quoted command that way (and maybe move cursor to end of line)
        echo "nvim -c 'AskViewTrace $assumed_file"
    else
        # extract the numeric part after the leading 't'
        set index_part (string replace --regex '^t' '' $abbreviation)
        set opts ""
        if string match --quiet --regex a $index_part
            set index_part (string replace --regex 'a' '' $index_part)
            set opts "--all"
        end
        # default to the first file if no number was provided
        if test -z "$index_part"
            set index_part 1
        end
        # find all trace files, sort them, and pick the Nth one
        set sorted_trace_files (fd --max-depth=1 ".*-trace\.json" . | sort)
        set selected_trace_file $sorted_trace_files[$index_part]

        if test -n "$selected_trace_file"
            echo "nvim -c 'AskViewTrace $opts $selected_trace_file'"
            # echo "view_trace $opts $file"
        else
            echo "nvim -c 'AskViewTrace $opts'"
            # echo "view_trace $opts"
        end
    end
end

function strip_trailing_newline --description "trim trailing \\n - last only"
    perl -0777 -pe 'chop if substr($_, -1) eq "\n"'
end

abbr bt browse_traces
abbr bta browse_traces agents
abbr btr browse_traces rewrite
abbr btf browse_traces fim
abbr btsh browse_traces fish
function browse_traces
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.chat_viewer.browser $argv
end
complete -c browse_traces -a '(command ls $WES_ASK_CAPTURES)' --no-files

abbr vt view_trace
function view_trace
    # Run the chat viewer tool using the module namespace.
    # ``tools`` is now a proper Python package, so we invoke the module with
    # ``-m tools.chat_viewer.__main__``. To ensure the package can be resolved,
    # add the repository root to ``PYTHONPATH``.
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.chat_viewer.__main__ $argv
end

abbr vtt view_trace_tui
function view_trace_tui
    # Interactive Textual chat viewer (a: toggle all content, q: quit).
    # Reuses the same rendering as ``view_trace`` but in a scrollable TUI.
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.chat_viewer.textual_viewer $argv
end

abbr td trace_dump
function trace_dump
    # Dump run_process commands from a trace file.
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.trace_dump $argv
end

abbr pii pii_scanner
function pii_scanner
    # Run the PII scanner tool using the module namespace.
    # tools is now a proper Python package, so we invoke the module with
    # -m tools.pii_scanner.__main__. To ensure the package can be resolved,
    # add the repository root to PYTHONPATH.
    set _python3 "$ASK_REPO/tools/pii_scanner/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.pii_scanner.__main__ $argv
end

abbr ri rag_indexer
function rag_indexer
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO/lua/ask-openai/rag" $_python3 -m indexer $argv
end

abbr rvi rag_validate_index
function rag_validate_index
    # find duplicate IDs, etc - basically sanity check on the faiss index IDs/vectors
    # capture rag dir of CURRENT repo
    set rag_dir (_repo_root)/.rag

    set _python3 "$ASK_REPO/.venv/bin/python3"
    # switch to directory to run the index.validate module... I could install this yes... for now I don't want to go that route
    fish -c "cd '$ASK_REPO/lua/ask-openai/rag'; $_python3 -m index.validate '$rag_dir' $argv"
end

abbr rag_rebuilder 'time rag_indexer --rebuild --info'

# **** MCP server wrappers
# FYI idea is to make it easier to configure MCP clients...
#    { "command": "fish", args: ["-c", "mcp_server_semantic_grep --root-dir /path/to/foo"] }
#    DO NOT use `fish -i` (interactive)... OSC codes (from iterm2 shell integration IIRC) will wreck you with STDOUT noise
# * semantic_grep MCP server entrypoint
function mcp_server_semantic_grep
    # BTW I prefer this wrapper approach vs pyproject.toml + project.scripts... these work without any install other than creating the venv initially
    #  then as the end user, I don't have to even think about venv/paths
    set _python3 "$ASK_REPO/.venv/bin/python3"
    #
    # TROUBLESHOOT WITH double tee fisting it:
    # tee /tmp/mcp_server_semantic_grep_STDIN.jsonl | env PYTHONPATH="$ASK_REPO/lua/ask-openai/rag" $_python3 -m mcp_server.__main__ $argv | tee /tmp/mcp_server_semantic_grep_STDOUT.jsonl
    env PYTHONPATH="$ASK_REPO/lua/ask-openai/rag" $_python3 -m mcp_server.__main__ $argv
end
complete -c mcp_server_semantic_grep --no-files
complete -c mcp_server_semantic_grep \
    --long-option root-dir \
    --description "Root directory for the operation" \
    --require-parameter \
    # complete directories nested under current directory (can also be anywhere on system)
    --arguments "(fd -t d .)" \
    --no-files

abbr trace_timings "jq --raw-output '.request_body.messages[].timings | select(.) | [.cache_n, .prompt_n, .predicted_n] | @tsv' ./*-trace.json | awk '{a+=\$1; b+=\$2; c+=\$3} END {print a \"\\t\" b \"\\t\" c}'"
#
abbr --add _tm --regex "tm\d+" --function _abbr_trace_message
function _abbr_trace_message --argument-names count
    set count (string replace -r '^[^\d]+' '' $count)
    set num_messages (jq '.request_body.messages | length' *-trace.json)
    if test $count -ge $num_messages
        set count (math "$num_messages - 1")
    end
    echo "cat *-trace.json | jq .request_body.messages[$count]"
end

abbr --add _tc --regex "tc\d+" --function _abbr_trace_command
function _abbr_trace_command --argument-names count
    set echo_msg (_abbr_trace_message $count)
    echo "$echo_msg.tool_calls.[].function.arguments --raw-output | jq .command_line --raw-output"
end

abbr --position anywhere --add msgargs --regex "msg(r|f|c|args|patch)?\d+" --function _abbr_msg_num
function _abbr_msg_num --argument-names to_expand
    # cat 1772355717-trace.json  | jq .request_body.messages[7].tool_calls[0].function.arguments -r | string split "\n" > test.patch
    # extractions:
    #  `msg7` => entire message
    #  `msgc7` => contents
    #  `msgargs7` => tool call args

    set num (math (string replace --regex '\D+' '' $to_expand) )
    set prefix (string replace --regex '\d+' '' $to_expand)

    set first_trace (fd "\-trace.json" | head -n 1)

    # dump messages
    echo -n "cat $first_trace | jq '.request_body.messages[$num]"
    if test "$prefix" = msg
        echo -n "'"
        return
    else if test "$prefix" = msgr
        echo -n ".reasoning_content' -r"
        return
    else if test "$prefix" = msgc
        echo -n ".content' -r"
        return
    else if test "$prefix" = msgf
        echo -n ".tool_calls[0].function'"
        return
    else if test "$prefix" = msgargs
        echo -n ".tool_calls[0].function.arguments' -r | jq '.'"
        return
    else if test "$prefix" = msgpatch
        echo -n ".tool_calls[0].function.arguments' -r | jq '.patch' -r | bat -l patch"
        return
    end
    echo "WHAT THE FUUU you smoking crack"
end
