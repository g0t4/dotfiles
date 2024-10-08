
# helpers (idea is always use pbcopy/paste -- see below)
abbr pwdcp "pwd | pbcopy"
abbr wdcp "pwd | pbcopy"

if not $IS_MACOS
    # on non-macs make it appear as if pbcopy/paste are available
    function pbcopy
        fish_clipboard_copy $argv
    end
    function pbpaste
        fish_clipboard_paste $argv
    end
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
# TODO if I `sudo su` to root user, I lose env vars without `sudo -E`... and so this logic isn't injected to copy... can I just make this always the case on linux?
#     IIAC I put this ssh check in for cases with WSL? would this just work even in WSL envs?
if test -n "$SSH_CLIENT"
    if command -q osc-copy
       # oscclip was removed from pypi in Aug 2024... and repo archived: https://github.com/rumpelsepp/oscclip?tab=readme-ov-file
        function fish_clipboard_copy
            # TODO think through this? is this robust? review fish_clipboard_copy
            # TODO do I wanna have my own wes_clipboard_copy that I use in special places so I am not trying to cover all other scenarios for using fish_clipboard_copy?
            osc-copy
            # osc-copy via => pipx install oscclip
        end
    end
    if command -q osc
        # osc suggested by https://github.com/rumpelsepp/oscclip?tab=readme-ov-file => https://github.com/theimpostor/osc
        #   go install -v github.com/theimpostor/osc@latest
        # so here is the wrapper to use it if present:
        function fish_clipboard_copy
            osc copy
        end
    end
    # else other osc copy commands?

    # NOT modifying fish_clipboard_paste b/c I am happy with paste via iterm2/winterm/etc
end

# yank + kill (clear)
bind \ek kill_whole_line_and_copy # esc+k (historically I used this key combo exclusively for this purpose)

# ctrl+c clear command line instead of cancel-commandline (why pollute terminal history to cancel a command!)
bind \cc 'commandline -r ""'
