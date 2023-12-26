
# modify delay to consider if esc key a seq or standalone
set fish_escape_delay_ms 200 # 30ms is default and way too fast (ie esc+k is almost impossible to trigger)

function kill_whole_line_and_copy
    # is there a better way to get last entry from kill ring instead of reading buffer (and trim newline) before kill?
    commandline -b | tr -d '\n' | fish_clipboard_copy
    commandline -f kill-whole-line
    # without copy to clipboard, have to use yank to paste removed line
end

bind \ek kill_whole_line_and_copy
