
# helpers (idea is always use pbcopy/paste -- see below)
ealias pwdcp="pwd | pbcopy"
ealias wdcp="pwd | pbcopy"

if not is_macos
    # alias pbcopy/paste (muscle memory for me)
    alias pbcopy fish_clipboard_copy
    alias pbpaste fish_clipboard_paste
    # NOTE fish alias == function (its not expanding)
    #   PRN expand pbcopy/paste? (don't hide shell specific mechanism)
    # fish_*_copy/paste call system specific backend (just like omz's clipcopy/clippaste)
    # don't alias on mac (b/c f_*_copy/paste uses pbcopy/paste... infinte loop fun)
end


# *** yank+copy binding:
function kill_whole_line_and_copy
    # is there a better way to get last entry from kill ring instead of reading buffer (and trim newline) before kill?
    commandline -b | tr -d '\n' | fish_clipboard_copy
    commandline -f kill-whole-line
    # without copy to clipboard, have to use yank to paste removed line
    # CONFIRMED fish_clipboard_copy works here on a mac
    # TODO TEST fish_clipboard_copy works here in WSL
end

bind \ek kill_whole_line_and_copy

# ctrl+c clear command line instead of cancel-commandline (why pollute terminal history to cancel a command!)
bind \cc 'commandline -r ""'
