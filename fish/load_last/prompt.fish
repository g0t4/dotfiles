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

    if set -q wes_recording_youtube_shorts_need_small_prompt
        # no login displayed
        return
    end

    # SSH indicator  or 
    #if set -q SSH_CONNECTION
    #    # keep in mind, have to update dotfiles for remote machines to pick up changes so this can't ever be assumed to be universal
    #    #echo -n -s (set_color cyan) \ue0a0 (set_color normal) " "
    #    echo -n -s (set_color cyan) \ue0a2 (set_color normal)
    #end

    #if test -f /.dockerenv
    #    # /.dockerenv => assume container
    #    # PRN add diff check like a custom env var I apply to my container images which is where this is most valuable so my dotifles indicate inside a container (just like SSH indicator above)
    #    echo -n -s (set_color cyan) \uf308 (set_color normal) " "
    #end

    if test -n "$VIRTUAL_ENV"
        ## venv indicator 
        echo -n -s (set_color cyan) \ue73c
        set base (basename $VIRTUAL_ENV)
        if test "$base" != ".venv"
            echo -n -s "$base"
        end
        if set -q show_verbose_prompt
            #  (dotfiles
            set venv_dir (basename (dirname $VIRTUAL_ENV))
            echo -n -s " ($venv_dir"
            echo -n -s "/$base)"
        end
        echo -n -s (set_color normal) " "
    end
    if set -q show_verbose_prompt
        echo -n -s $USER@$hostname
        return
    end

    # show hostname
    if string match -q "mbp*" $hostname
        # for duration of course, make host clear and not confusing (just mac in this case) - otherwise dir alone mighe be ubuntu (in vms/ubuntu dir) and then its just "ubuntu" without hostname and that might lead one to believe it's the ubuntu course VM
        echo -n -s mac
    else
        # strip .lan, .local from hostname
        set display_hostname (string replace -r "\.lan\$|\.local\$" "" $hostname)
        echo -n -s $display_hostname
    end

    # selectively show hostname
    # if not string match -q "mbp*" $hostname
    #     # chances of showing hostname and python icon are low so don't worry about leading space here b/c then I have to disable it when not python icon and that's yuck
    # else if string match -rq "$HOME/repos/github/g0t4/course2-mdls" $PWD
    #     # in course repo show hostname as mac (temp just for course)
    #     echo -n -s "host"
    # end

    return
end

function prompt_pwd --description 'wes mod - name of the current dir only'

    # if recording shorts, show a small prompt
    if set -q wes_recording_youtube_shorts_need_small_prompt
        return
    end
    # variable named
    # PRN flush out other scenarios like I have with ~/repos/github/g0t4/foo => gh:g0t4/foo
    if set -q show_verbose_prompt
        _pwd
        return
    end

    set -l color_cwd $fish_color_cwd
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
    end
    echo -n -s (set_color $color_cwd)

    # truncate long course paths
    if string match --regex -q "$HOME/repos/github/g0t4/private-course-rancher\$" $PWD
        echo -n -s private-course
        return
    end
    if string match -q "$HOME/repos/github/g0t4/course-rancher" $PWD
        echo -n -s course
        return
    end

    # if in repo root (not nested dir), then show org/repo
    #   based on _pwd
    set _rr (_repo_root)
    if string match -q -r '(?<host_dir>.*/(bitbucket|github|gitlab))/(?<repo>.*)' $_rr
        # make sure not in a nested dir
        set prefix (git rev-parse --show-prefix 2>/dev/null)
        if test "$prefix" = ""
            echo -n -s (set_color cyan) $repo
            return
        end
    end

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

    # Write status
    # - only if command was run in previous prompt
    # - GOAL: clear status (in prompt) simply by hitting ENTER (empty prompt), followed by CMD+K to clear screen too
    #        b/c exit code (prompt_status) is part of prompt, cannot clear it w/ just CMD+K b/c the prompt is just redrawn, hence RETURN first then Cmd+K
    # FYI $status_generation is incremented each time a command is actually run (so, not when empty prompt submitted)
    if set -q __fish_prompt_last_displayed_status_generation
        and not test $__fish_prompt_last_displayed_status_generation = $status_generation
        # new status (generated) => show it
        set -l status_color (set_color $fish_color_status)
        set -l statusb_color (set_color --bold $fish_color_status)
        set prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)
        # FYI ❤️ presentation of exit codes / status from __fish_print_pipestatus (aside from now effectively unused bold color part)
    end
    set --global __fish_prompt_last_displayed_status_generation $status_generation
    # test these scenarios:
    # false => shows [1] on next prompt, return clears
    # true never shows anything
    # sleep 10 => Ctrl+C => shows [SIGINT]
    # true | false => shows [0|1] on next prompt, return clears
    if set -q prompt_status
        and test -n "$prompt_status"
        echo -s $prompt_status $normal

        # ! only downside is this may screw up smth else... so be prepared... i.e. I might confuse the line as part of output of prev command... that said, if I pipe to smth else it won't be a problem b/c this is part of the prompt

        # test:    true | false => shows [0|1]
        # ~ zsh's setopt PRINT_EXIT_VALUE (print non-zero exit code after command, before next prompt)
        # why?
        # - clear w/ Cmd+K alone... previously had to RETURN => CMD+K to fully clear screen
        # - I love being smacked in the face with a non-zero exit code
        #   - I don't like having it get in the way of typing my next command (ie prompt suddenly wider, then smaller)
        # FYI long ago I modified prompt to not show the prior command's exit code until the next command is run (that really drove me bonkers)
    end

    set -l suffix '>'
    if functions -q fish_is_root_user; and fish_is_root_user
        set suffix '#'
    end

    # leave $normal after components so they can add color:
    echo -n -s (prompt_login)' ' (prompt_pwd) $normal (fish_vcs_prompt) $normal $suffix " "
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
