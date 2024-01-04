
# helpers (idea is always use pbcopy/paste -- see below)
ealias pwdcp="pwd | pbcopy"
ealias wdcp="pwd | pbcopy"

# alias pbcopy/paste (muscle memory for me)
alias pbcopy="fish_clipboard_copy"
alias pbpaste="fish_clipboard_paste"
# NOTE fish alias == function (its not expanding)
#   PRN expand pbcopy/paste? (don't hide shell specific mechanism)
# fish_*_copy/paste call system specific backend (just like omz's clipcopy/clippaste)
# PRN - if I have issues using these aliases to fish_*_copy/paste on a mac then I can skip these aliases on macs and go back to directly using pbcopy/paste

# *** yank+copy binding:
function kill_whole_line_and_copy
    # is there a better way to get last entry from kill ring instead of reading buffer (and trim newline) before kill?
    commandline -b | tr -d '\n' | fish_clipboard_copy
    commandline -f kill-whole-line
    # without copy to clipboard, have to use yank to paste removed line
end

bind \ek kill_whole_line_and_copy

# ctrl+c clear command line instead of cancel-commandline (why pollute terminal history to cancel a command!)
bind \cc 'commandline -r ""'
