function prompt_login --description 'display user name for the prompt'
    if test -n "$VIRTUAL_ENV"
        echo -n -s (set_color cyan) \ue73c (set_color normal)
    end
    return
end
