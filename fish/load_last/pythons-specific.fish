function wcl

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _wcl_py "$WES_DOTFILES/zsh/compat_fish/pythons/wcl.py"

    $_python3 $_wcl_py $argv

end

# completions:
complete -c wcl --no-files
complete -c wcl --long-option path-only --description 'Only print the path'
complete -c wcl --long-option dry-run
