function wcl

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/wcl.py"

    $_python3 $_script_py $argv

end

# completions:
complete -c wcl --no-files
complete -c wcl --long-option path-only --description 'Only print the path'
complete -c wcl --long-option dry-run

# PRN complete with gh repo list... with my repos
# complete -c wcl -a '(gh repo list --json nameWithOwner --jq .[].nameWithOwner --limit 1000)' -f

function wrc

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/wrc.py"

    $_python3 $_script_py $argv

end
