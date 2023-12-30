function wcl

  set -l _python3 "$WES_BOOTSTRAP/.venv/bin/python3"
  set -l _wcl_py "$WES_DOTFILES/zsh/universals/3-last/wcl/wcl.py"

  $_python3 $_wcl_py $argv

end
