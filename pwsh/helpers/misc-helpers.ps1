
function wcl() {

  $_python = "${WESCONFIG_DOTFILES}\.venv\Scripts\python.exe"
  $_wcl_py = "${WESCONFIG_DOTFILES}\zsh\compat_fish\pythons\wcl.py"
  & $_python $_wcl_py $args

}

# TODO wrap z command like I did with fish shell
#   see notes in wcl.py about how to approach this to obviate the need to add the path to z history in wcl.py too