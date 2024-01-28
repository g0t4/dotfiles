
function fish_vcs_prompt --description 'Print all vcs prompts'
    # If a prompt succeeded, we assume that it's printed the correct info.
    # This is so we don't try svn if git already worked.
    #fish_git_prompt $argv
    #or fish_hg_prompt $argv
    # The svn prompt is disabled by default because it's quite slow on common svn repositories.
    # To enable it uncomment it.
    # You can also only use it in specific directories by checking $PWD.
    # or fish_svn_prompt
end

function prompt_login --description 'display user name for the prompt'
    # prompt_login is effectively the start of the prompt

    # show python icon if in a venv
    if test -n "$VIRTUAL_ENV"
        echo -n -s (set_color cyan) \ue73c (set_color normal)
    end

    # selectively show hostname
    if not string match -q "mbp*" $hostname
        # chances of showing hostname and python icon are low so don't worry about leading space here b/c then I have to disable it when not python icon and that's yuck
        echo -n -s $hostname
    end

    return
end

function prompt_pwd --description 'wes mod - name of the current dir only'
    # PRN flush out other scenarios like I have with ~/repos/github/g0t4/foo => gh:g0t4/foo
    # ~ for home dir
    if string match -q "$HOME" $PWD
        echo -n -s "~"
        return
    end
    basename $PWD
end

function fish_title
    # blank for now, never been a big fan of tab titles changing per directory or otherwise, probably b/c cd'ing in another tab between recordings leads to change on-screen that is needless (I don't find myself using the titles to navigate so its pointless friction for screen caps)
    echo $USER
    # FYI must set to something (can't be blank) else iTerm will show profile name (initially and then that sticks, haven't found setting to get it to stop that)
    # TERM_PROGRAM iTerm.app
end

# Defined in /opt/homebrew/Cellar/fish/3.7.0/share/fish/functions/fish_prompt.fish @ line 4
function fish_prompt_modified --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '>'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    # Write status
    # - only if command was run in previous prompt
    # - goal: clear status (in prompt) simply by hitting enter (empty prompt), followed by cmd+k to clear screen too
    # FYI $status_generation is incremented each time a command is actually run (so, not when empty prompt submitted)
    if set -q __fish_prompt_last_displayed_status_generation
        and not test $__fish_prompt_last_displayed_status_generation = $status_generation
        # new status (generated) => show it
        set -l status_color (set_color $fish_color_status)
        set -l statusb_color (set_color --bold $fish_color_status)
        set prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)
    end
    set --global __fish_prompt_last_displayed_status_generation $status_generation
    # test these scenarios:
    # false => shows [1] on next prompt, return clears
    # true never shows anything
    # sleep 10 => Ctrl+C => shows [SIGINT]
    # true | false => shows [0|1] on next prompt, return clears

    echo -n -s (prompt_login)' ' (set_color $color_cwd) (prompt_pwd) $normal (fish_vcs_prompt) $normal " "$prompt_status $suffix " "
end

# redefine (wrap)
function fish_prompt
    # PRN could also drop showing status of previous command (or rearrange it) w/o reimplementing fish_prompt

    # FYI these glyphs are added to nerd fonts and most are specifically from: https://github.com/ryanoasis/powerline-extra-symbols
    #     \ue0c1
    # 
    #   \ue0c8
    #    \ue0b5
    #   \uf307
    # ❯
    # ) # ** esp like
    # 
    # 
    # 
    # ↝
    set replace_with ")"
    fish_prompt_modified | string replace ">" $replace_with
end

### *** idea for showing status code right before drawing prompt instead of in the prompt:
#   inspired by zsh's option to show status after command runs: setopt prompt_subst
# function after_command --on-event fish_postexec
#     echo 'command result: '$status
# end
