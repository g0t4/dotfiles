# for non-interactive TOO

function _shorts
    set --universal wes_recording_youtube_shorts_need_small_prompt 1
end

function _not_shorts
    set --erase wes_recording_youtube_shorts_need_small_prompt
end

function _recording

    # PRN if calling repeatedly (ie on spal activate) causes problems => return if already in recording mode?

    _disable_fish_suggestions

    # ? use diff history file i.e. for ctrl+R history pager search
    # set -U fish_history recording # ~/.local/share/fish/recording_history

    # TODO disable showing return code failures in prompt? wait to see how much of a hassle this is when editing some new videos

    # FYI - I added Keyboard Maestro macros to:
    #   on screenpal (launch or activate) =>
    #       /opt/homebrew/bin/fish -c "_recording" 2>&1
    #       PRN on activate too?
    #       FYI can take a second or two to apply to all windows
    #   on screenpal quits =>
    #       /opt/homebrew/bin/fish -c "_not_recording" 2>&1
    # ?? PRN quicktime too?

end

function _not_recording
    _enable_fish_suggestions
    # set -U fish_history default # revert to ~/.local/share/fish/fish_history
end

function _disable_fish_suggestions
    #https://fishshell.com/docs/current/language.html#envvar-fish_autosuggestion_enabled
    set -U fish_autosuggestion_enabled 0
    # -U => universal applies to all windows (can be slight lag to apply to all windows, but most of the time its nearly immediate)
end

function _enable_fish_suggestions
    set -U fish_autosuggestion_enabled 1
end

# *** python

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
function abbr_expand_trace_nth_file
    set original $argv[1]
    # extract the numeric part after the leading 't'
    set index (string replace --regex '^t' '' $original)
    if string match --quiet --regex a $index
        set index (string replace --regex 'a' '' $index)
        set opts --all
    else
        set opts ""
    end
    # default to the first file if no number was provided
    if test -z "$index"
        set index 1
    end
    # find all trace files, sort them, and pick the Nth one
    set files (fd --max-depth=1 ".*-trace\.json" . | sort)
    set file $files[$index]

    if test -n "$file"
        echo "view_trace $opts $file"
    else
        echo "view_trace $opts"
    end
end

function strip_trailing_newline --description "trim trailing \\n - last only"
    perl -0777 -pe 'chop if substr($_, -1) eq "\n"'
end

abbr ba browse_traces agents
abbr br browse_traces rewrite
abbr bf browse_traces fim
abbr bsh browse_traces fish
function browse_traces
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.chat_viewer.browser $argv
end
complete -c browse_traces -a '(command ls $WES_ASK_CAPTURES)' --no-files

function view_trace
    # Run the chat viewer tool using the module namespace.
    # ``tools`` is now a proper Python package, so we invoke the module with
    # ``-m tools.chat_viewer.__main__``. To ensure the package can be resolved,
    # add the repository root to ``PYTHONPATH``.
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.chat_viewer.__main__ $argv
end

complete -c trace_dump -l plain-text -d 'Output plain text without colors or panel borders'
function trace_dump
    # Dump run_process commands from a trace file.
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.trace_dump $argv
end

complete -c pii_scanner -a '--model --threshold --json --show-matches --extract-paths help' --no-files
abbr -- pbpii 'pii_scanner (pbpaste | string split "\n" | string trim | psub)'
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
    set _script_py "$ASK_REPO/lua/ask-openai/rag/indexer.py"
    $_python3 $_script_py $argv
end

abbr rvi rag_validate_index
function rag_validate_index
    # find duplicate IDs, etc - basically sanity check on the faiss index IDs/vectors
    # capture rag dir of CURRENT repo
    set rag_dir (_repo_root)/.rag

    set _python3 "$ASK_REPO/.venv/bin/python3"
    # switch to directory to run the index.validate module... I could install this yes... for now I don't want to go that route
    fish -c "cd '$ASK_REPO/lua/ask-openai/rag'; '$_python3' -m index.validate '$rag_dir'"
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

# helpers for mcp messages
set mcp_init '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
set mcp_tool_list '{ "jsonrpc": "2.0", "id": 2, "method": "tools/list" }'
abbr mcp_copy_init "echo -e '$mcp_init\n$mcp_tool_list'  | pbcopy"
# set mcp_init_notification '{"jsonrpc":"2.0","method":"notifications/initialized"}' # not required to respond with this, but put it here in case I need it at some point
