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

if not status is-interactive
    # improve behaviors when agents use tool calls via fish?
    # apparently Claude uses zsh... and did smth funky with my zsh config, leave this just in case at some point I wanna cleanup and use fish as the shell...
    #  also doesn't hurt to have non interactive processes not use ANSI color codes... though I bet some edge case will bite me... we shall see
    functions --erase ls # use stock ls command
end
