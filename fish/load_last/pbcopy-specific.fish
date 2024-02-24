
# helpers (idea is always use pbcopy/paste -- see below)
eabbr pwdcp "pwd | pbcopy"
eabbr wdcp "pwd | pbcopy"

if not is_macos
    # on non-macs make it appear as if pbcopy/paste are available
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
end

# if SSH => replace fish_clipboard_copy
if test -n "$SSH_CLIENT"
    if command -q osc-copy
        function fish_clipboard_copy
            # TODO think through this? is this robust? review fish_clipboard_copy
            # TODO do I wanna have my own wes_clipboard_copy that I use in special places so I am not trying to cover all other scenarios for using fish_clipboard_copy?
            osc-copy
            # osc-copy via => pipx install oscclip
        end
    end
    # else other osc copy commands?

    # NOT modifying fish_clipboard_paste b/c I am happy with paste via iterm2/winterm/etc
end

bind \ek kill_whole_line_and_copy

# ctrl+c clear command line instead of cancel-commandline (why pollute terminal history to cancel a command!)
bind \cc 'commandline -r ""'
