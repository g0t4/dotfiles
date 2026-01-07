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
    # PRN pass thread file
    # use this to diff a thread.json file, to grab the response_message's content and diff that vs the original selection in the last user message(request_body.messages[-1].content)
    #  the bulk of the input and output are likely the selected code to rewrite, especially for large selections...
    #  also shows user request too
    #  model wise the model should only return rewritten code so it shouldn't have anything extra, unless it derps up markdown w/ explanations of its changes
    diff_two_commands 'jq .request_body.messages[-1].content -r *-thread.json' 'jq .response_message.content -r *-thread.json'
end

abbr thread ask_thread_reviewer
function ask_thread_reviewer
    set _python3 "$ASK_REPO/.venv/bin/python3"
    set _script_py "$ASK_REPO/tools/chat_viewer/__main__.py"

    if not isatty stdin
        # * STDIN takes priority
        $_python3 $_script_py
        return
    end

    set passed_path $argv[1]
    if not is_empty $passed_path; and test -f $passed_path
        # * single file wins
        $_python3 $_script_py $passed_path
        return
    end

    # * look for common log files
    set found_json_file ""
    set look_in_dir "$passed_path"
    if is_empty "$look_in_dir"
        # empty searches current directory
        set look_in_dir "."
    end
    if test -d $look_in_dir
        # * look for common names in directory
        if count $look_in_dir/*-thread.json >/dev/null
            # FYI count fails if no matches
            # keep in mind this can match multiple files, will cause error below
            set found_json_file $look_in_dir/*-thread.json
        else if test -f $look_in_dir/input-messages.json
            set found_json_file $look_in_dir/input-messages.json
        else if test -f $look_in_dir/input-body.json
            set found_json_file $look_in_dir/input-body.json
        end
    end

    if test (count $found_json_file) != 1
        echo "ONE file must be provided (or use STDIN), aborting..."
        echo -en "  file(s) passed:\n    " >&2
        echo -e (string join "\n    " $found_json_file) >&2
        return 1
    end

    $_python3 $_script_py $found_json_file
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
