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
    if test -n "$VIRTUAL_ENV"
        echo -n -s (set_color cyan) \ue73c (set_color normal)
    end
    return
end

function prompt_pwd --description 'wes mod - name of the current dir only'
    # PRN flush out other scenarios like I have with ~/repos/github/g0t4/foo => gh:g0t4/foo
    basename $PWD
end
