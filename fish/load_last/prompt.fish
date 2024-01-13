
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

# ** modify top level fish_prompt
if not functions -q original_fish_prompt
    # make idempotent for _reload_config which I use to test out new prompts
    functions --copy fish_prompt original_fish_prompt
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
    original_fish_prompt | string replace ">" $replace_with
end

### *** idea for showing status code right before drawing prompt instead of in the prompt:
#   inspired by zsh's option to show status after command runs: setopt prompt_subst
# function after_command --on-event fish_postexec
#     echo 'command result: '$status
# end