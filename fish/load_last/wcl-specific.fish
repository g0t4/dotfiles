function wcl

  set -l _python3 "$WESCONFIG_BOOTSTRAP/.venv/bin/python3"
  set -l _single_py "$WES_DOTFILES/zsh/universals/3-last/wcl/wcl.py"

  $_python3 $_single_py $argv

end
