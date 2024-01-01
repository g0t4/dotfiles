
# modify delay to consider if esc key a seq or standalone
set fish_escape_delay_ms 200 # 30ms is default and way too fast (ie esc+k is almost impossible to trigger)

function kill_whole_line_and_copy
    # is there a better way to get last entry from kill ring instead of reading buffer (and trim newline) before kill?
    commandline -b | tr -d '\n' | fish_clipboard_copy
    commandline -f kill-whole-line
    # without copy to clipboard, have to use yank to paste removed line
end

bind \ek kill_whole_line_and_copy

# ctrl+c clear command line instead of cancel-commandline (why pollute terminal history to cancel a command!)
bind \cc 'commandline -r ""'

# PRN add a binding to clear screen + reset status of last run command (so prompt doesn't have last non-zero exit code)
#   FYI default binding ctrl+l:
#      bind --preset \cl echo\ -n\ \(clear\ \|\ string\ replace\ \\e\\\[3J\ \"\"\)\;\ commandline\ -f\ repaint
#  clear; true; # some sort of yank to killring (entire line), then have to run true command to change status, then clear again and paste original input back from killring? (sounds overly complicated... perhaps I could just find a way to modify the prompt condition to not show status after clearing screen (if no longer see previuos command output what is the point?))