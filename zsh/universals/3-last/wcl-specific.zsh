function wcl() {

  _python3="${WESCONFIG_BOOTSTRAP}/.venv/bin/python3"
  _wcl_py="${WESCONFIG_DOTFILES}/zsh/universals/3-last/wcl/wcl.py"

  $_python3 $_wcl_py $argv

}
