function wcl

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _wcl_py "$WES_DOTFILES/zsh/compat_fish/pythons/wcl.py"

    $_python3 $_wcl_py $argv

end
