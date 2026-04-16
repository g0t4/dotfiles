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

abbr --function _abbr_expand_t t
function _abbr_expand_t
    expand_with_first_file_match view_trace ".*-trace.json"
end
function expand_with_first_file_match --argument-names cmd match_regex
    set first_file_match (fd --max-depth=1 $match_regex | head -1)
    if set -q first_file_match
        echo "$cmd $first_file_match"
    else
        echo $cmd
    end
end

function strip_trailing_newline --description "trim trailing \\n - last only"
    perl -0777 -pe 'chop if substr($_, -1) eq "\n"'
end

function view_trace
    set _python3 "$ASK_REPO/.venv/bin/python3"
    set _script_py "$ASK_REPO/tools/chat_viewer/__main__.py"
    $_python3 $_script_py $argv
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
