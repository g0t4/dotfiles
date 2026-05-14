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

abbr --add abbr_trace_nth_file --regex 't\d*' --function abbr_expand_trace_nth_file
function abbr_expand_trace_nth_file
    set -l match $argv[1]
    # extract the numeric part after the leading 't'
    set -l index (string replace -r '^t' '' $match)
    # default to the first file if no number was provided
    if test -z "$index"
        set index 1
    end
    # find all trace files, sort them, and pick the Nth one
    set -l files (fd --max-depth=1 ".*-trace\.json" . | sort)
    set -l file $files[$index]

    if test -n "$file"
        echo "view_trace $file"
    else
        echo view_trace
    end
end

function strip_trailing_newline --description "trim trailing \\n - last only"
    perl -0777 -pe 'chop if substr($_, -1) eq "\n"'
end

abbr ba browse_traces agents
abbr br browse_traces rewrite
abbr bf browse_traces fim
function browse_traces
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.chat_viewer.browser $argv
end
complete -c browse_traces -a 'rewrite fim agents' --no-files

function view_trace
    # Run the chat viewer tool using the module namespace.
    # ``tools`` is now a proper Python package, so we invoke the module with
    # ``-m tools.chat_viewer.__main__``. To ensure the package can be resolved,
    # add the repository root to ``PYTHONPATH``.
    set _python3 "$ASK_REPO/.venv/bin/python3"
    env PYTHONPATH="$ASK_REPO" $_python3 -m tools.chat_viewer.__main__ $argv
end

function rag_indexer
    set _python3 "$ASK_REPO/.venv/bin/python3"
    set _script_py "$ASK_REPO/lua/ask-openai/rag/indexer.py"
    $_python3 $_script_py $argv
end

function rag_validate_index
    # find duplicate IDs, etc - basically sanity check on the faiss index IDs/vectors
    # capture rag dir of CURRENT repo
    set rag_dir (_repo_root)/.rag

    set _python3 "$ASK_REPO/.venv/bin/python3"
    # switch to directory to run the index.validate module... I could install this yes... for now I don't want to go that route
    fish -c "cd '$ASK_REPO/lua/ask-openai/rag'; '$_python3' -m index.validate '$rag_dir'"
end

abbr rag_rebuilder 'time rag_indexer --rebuild --info'
