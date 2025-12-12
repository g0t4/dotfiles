set fish_greeting ""

# OPTIMIZE readlink/dirname calls here are very expensive (2,4,2 ms on each of these three lines - fix this)
if test (uname) = Darwin
    set -g IS_MACOS true
    set -g IS_LINUX false
else
    # assume linux, differentiate distros later if needed
    set -g IS_MACOS false
    set -g IS_LINUX true
end

# FYI stick with WES_ prefix to namespace my variables
export WES_REPOS="$HOME/repos"
set -g WES_BOOTSTRAP "$WES_REPOS/wes-config/wes-bootstrap"
set -g WES_DOTFILES "$WES_REPOS/github/g0t4/dotfiles"
export WES_DOTFILES=$WES_DOTFILES

# ** load_first
if status is-interactive
    for file in $WES_DOTFILES/fish/load_first/interactive_only/*.fish
        source $file
    end
end
# non-interactive scripts
for file in $WES_DOTFILES/fish/load_first/*.fish
    source $file
end

# * zsh compat
if status is-interactive
    # largely abbrs, a few env vars that might need moved... so, defensively load these interactive only
    for file in $WES_DOTFILES/zsh/compat_fish/*.zsh
        source $file
    end
end

# ** load_last
for file in $WES_DOTFILES/fish/load_last_interactive_only/always/*.fish
    # both interactive and non-interactive
    source $file
end
if status is-interactive
    for file in $WES_DOTFILES/fish/load_last_interactive_only/*.fish
        source $file
    end
end

# optional, private config
if test -f $HOME/.config/fish/config-private.fish
    source $HOME/.config/fish/config-private.fish
end

if status is-interactive
    # optional, iterm2 shell integration (must be installed here, i.e. by installing via iterm menus)
    if test -e $HOME/.iterm2_shell_integration.fish

        source $HOME/.iterm2_shell_integration.fish

        # *** ask-openai variables to identify env (i.e. sshed to a remote shell):
        if test -f /etc/os-release
            set ask_os (cat /etc/os-release | grep '^ID=' | cut -d= -f2)
        else
            set ask_os (uname) # Darwin, Linux, etc
        end

        function split_pwd_on_path_change --on-variable PWD
            # this is a hack to fix the fact that "path" variable is not reliable
            #   when a program is running remotely (over SSH)
            #   the path flips to a local path
            #   run `sleep 60` and check Inspector to see this happen
            #   when program halts, it reverts to a correct, remote, path

            # this is for my iTerm2 split pane/tab/window and preserve path/SSH combo
            if functions -q iterm2_set_user_var
                iterm2_set_user_var split_path $PWD
            end
        end

        function iterm2_print_user_vars
            # mostly to avoid stale values after exist SSH, to set back to values the host has
            # FYI this is called by iterm2_shell_integration.fish on every prompt
            iterm2_set_user_var ask_shell fish
            # FYI caching value in $ask_os, to avoid penality on every prompt
            iterm2_set_user_var ask_os "$ask_os"
        end
    end
end

# TMP use bash if CWD is course dir
#  KEEP THIS AT END OF startup files so it doesn't block loading something else that might matter... just in case
# if status --is-interactive
#     # don't want for non-interactive (i.e. fish -c "...")
#     if string match --quiet --regex "g0t4/.*course.*-bash.*" "$(_repo_root)"
#         bash
#     end
# end
