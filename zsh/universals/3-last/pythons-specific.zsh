function wcl() {

  _python3="${WESCONFIG_DOTFILES}/.venv/bin/python3"
  _wcl_py="${WESCONFIG_DOTFILES}/zsh/compat_fish/pythons/wcl.py"

  $_python3 $_wcl_py $argv

}
