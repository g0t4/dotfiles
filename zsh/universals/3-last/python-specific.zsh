# COMPLETIONS - zsh bundles _pip/_python completions
#  - pro: zsh pip completions work on package names! cursory testing of pip/python native completions indicates they don't support package names...
#    - complete pkg names way more valuable
#  - con: OOB zsh completions are not complete arg wise and I'm not sure how often they are updated... I should familiarize myself with making a contrib for this (I saw that github clone of zsh supports completion contribs... sounds like listserve is where most do it)

# why `command` => `command3`?
#   i.e. pip => pip3, python => python3
#   global interpreter => command3 is ubiquitous AND recommended (for the default 3.X version)
#   venv => command3 defined (for all v3 venvs!)
# use ipython b/c it reminds me its REPL is VASTLY superior (color, tab completion, etc)
abbr ipy 'ipython3' # ipython is much slower to start so don't default to it unless I explicitly want it
# TODO why is ipython startup like seconds longer?
abbr py 'python3'
abbr python 'python3'
abbr pip 'pip3'

# PRN go back to python3.10/11 etc in ve* abbrs?
### VENV (--clear allows to recreate venv if already dir exists, --upgrade-deps makes sure pip is latest)
abbr ve 'python3 -m venv --clear --upgrade-deps'
abbr vedir 'echo $VIRTUAL_ENV'
abbr veinit 'python3 -m venv --clear --upgrade-deps .venv && vea' # PRN follow with pip install -r requirements.txt (if req file exists)
abbr veinitr 'python3 -m venv --clear --upgrade-deps .venv && vea && pip3 install -r requirements.txt'
# PRN make install requirements.txt conditional on its presence in current dir => i.e. fish abbreviation + function
abbr veinitl 'python3 -m venv --clear --upgrade-deps .venv.local && vea'

# manually activate/deactivate a venv, remember I have my autovenv plugin that will activate on cd
# FYI use activate.fish for fish (override is in python-specific.fish)
abbr ved 'deactivate'
abbr vea 'source .venv*/bin/activate' # .venv* allows for .venv or .venv.local (my two choices for venv names)


### pipx ###
abbr pipxi 'pipx install'
abbr pipxir 'pipx install -r requirements.txt'
abbr pipxip 'pipx install --python'
abbr pipxls 'pipx list'
abbr pipxrp 'pipx runpip' # ie to install pypi deps (of primary command), i.e.:
#  pipx install ansible
#  pipx runpip ansible install toml  # add toml dependency, i.e. used by ansible-inventory --toml
abbr pipxr 'pipx run' # think `npx foo`

### PIP ###
abbr pipls 'pip3 list'
abbr piplo 'pip3 list --outdated'

abbr pipir 'pip3 install -r requirements.txt'
abbr pipi 'pip3 install'

abbr pipup 'pip3 install --upgrade '
abbr pipupp 'pip3 install --upgrade pip'

# uninstall all packages:
abbr pipun 'pip3 uninstall -y $(pip3 freeze)'
abbr pipunu 'pip3 uninstall -y $(pip3 freeze --user)' # --user site (if applicable)


function wcl() {

  _python3="${WES_DOTFILES}/.venv/bin/python3"
  _wcl_py="${WES_DOTFILES}/zsh/compat_fish/pythons/wcl.py"

  $_python3 $_wcl_py $argv

}
