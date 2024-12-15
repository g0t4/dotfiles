
# helpers (idea is always use pbcopy/paste -- see below)
abbr pwdcp cppath # reminder, hopefully cppath stick with me but we shall see..
# I am tempted to leave pwdcp and let it take the relative path arg too :), basically alias cppath without abbr expansion

function cppath
    # no args => pwd
    # 1 arg ~= pwd + relative path (no resolve symlinks)
    #   do not resolve symlinks
    #   so you can do `cppath README.md` to grab the path to the README.md file
    #   inspired by pwdcp and wanting to be able to use it to include filenames too

    set _path (_cppath $argv)
    if test $status -ne 0
        # make sure to show error message, and indicate failure
        echo $_path
        return 1
    end

    # if spaces in path, need to wrap in `'` for pbcopy to work
    if string match --regex --quiet -- ' ' "$_path"
        echo "'$_path'" | pbcopy
    else
        echo "$_path" | pbcopy
    end
end

function _cppath
    if test -z "$argv"
        # no args => pwd only
        pwd
        return 0
    end

    if command -q grealpath
        grealpath --no-symlinks "$argv"
    else if uname | grep -q Darwin
        # macOS version of realpath doesn't have --no-symlinks option
        echo "FAIL: grealpath not found and is needed on macOS (brew install coreutils)"
        return 1
    else
        # s/b linux only here:
        realpath --no-symlinks "$argv"
    end
end


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

# *** Esc+K => yank+copy binding:

function kill_all_lines
    #commandline -C 0 # move to start of prompt
    commandline -b | fish_clipboard_copy # copies all lines of cmdline (not just current line)
    commandline -r "" # replace all lines with empty string
end
bind \ek kill_all_lines # esc+k (historically I used this key combo exclusively for this purpose)

# ctrl+c clear command line instead of cancel-commandline (why pollute terminal history to cancel a command!)
bind \cc 'commandline -r ""'
