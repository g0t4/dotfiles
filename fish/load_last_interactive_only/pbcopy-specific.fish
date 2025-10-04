
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
        echo -n "'$_path'" | pbcopy
    else
        echo -n "$_path" | pbcopy
    end
end

function _cppath
    if test -z "$argv"
        # no args => pwd only
        command pwd
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

# abbr pbp pbpaste
abbr pb pbpaste
abbr pbj "pbpaste | jq"
#
# abbrs for openai compatible json parsing
abbr pbj_toolcall_args "pbpaste | jq '.tool_calls[0].function.arguments' -r"
#
abbr pby "pbpaste | yq"
abbr pbw "pbpaste | wordcount"
abbr pbn "pbpaste | string split '\n'"

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
        echo "osc-copy found, using it for pbcopy, please install osc instead"
    end
    if command -q osc
        # osc suggested by https://github.com/rumpelsepp/oscclip?tab=readme-ov-file => https://github.com/theimpostor/osc
        #   go install -v github.com/theimpostor/osc@latest
        # so here is the wrapper to use it if present:
        function fish_clipboard_copy
            osc copy
        end
        function fish_clipboard_paste
            osc paste
        end
    end
    # else other osc copy commands?

    # NOT modifying fish_clipboard_paste b/c I am happy with paste via iterm2/winterm/etc
end

# *** Esc+K => yank+copy binding:

function kill_all_lines
    #commandline -C 0 # move to start of prompt

    # use perl to cut off last new line at end of file... why the FUCK is it added by commandline -b???
    # if there is a new line at the end of the last line, pasting in iTerm2 warns/prompts to paste w/o new line, otherwise I might not give a F
    commandline -b | perl -pe 'chomp if eof' | pbcopy # copies all lines of cmdline (not just current line)

    commandline -r "" # replace all lines with empty string
end
bind_both_modes_default_and_insert escape,k kill_all_lines # esc+k (historically I used this key combo exclusively for this purpose)
bind_both_modes_default_and_insert alt-k kill_all_lines # should I switch to alt for my meta key basically? just explicitly set it for all shortcuts I used to use with esc (very few)?
# one reason to switch to alt is b/c nvim then can use esc to exit to normal mode from terminal mode

# !!! TODO USE THIS LATER...
#function pre_exec_set_CMDLINE_env_var --on-event fish_preexec
#    # this way the command that is running can introspect what is running!
#    # would I be able to run grc too, based on command contents? and not need the line to show it prepended?
#    # also, if bat runs at end of pipeline, it could look at cmdline to determine the filetype that is piped to it
#    # or grcat on end of pipeline could match on what is running just like grc does... no need for grc in front anymore
#    #    PRN could I write a grcatwrapper that I could echo foo | grcatwrapper and have it do w/e grc does when grc is in front? (pass off params to grcat)
#
#    # first arg is the cmdline
#    export FISH_CURRENT_CMDLINE=$argv
#end


# *** cp
abbr cpr "cp -r"
