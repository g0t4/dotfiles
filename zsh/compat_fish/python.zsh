# COMPLETIONS - zsh bundles _pip/_python completions
#  - pro: zsh pip completions work on package names! cursory testing of pip/python native completions indicates they don't support package names...
#    - complete pkg names way more valuable
#  - con: OOB zsh completions are not complete arg wise and I'm not sure how often they are updated... I should familiarize myself with making a contrib for this (I saw that github clone of zsh supports completion contribs... sounds like listserve is where most do it)

# why `command` => `command3`?
#   i.e. pip => pip3, python => python3
#   global interpreter => command3 is ubiquitous AND recommended (for the default 3.X version)
#   venv => command3 defined (for all v3 venvs!)
ealias python='python3'
ealias py='python3'
ealias pip='pip3'
ealias pydoc='pydoc3'
ealias python-config='python3-config'

### VENV (--clear allows to recreate venv if already dir exists, --upgrade-deps makes sure pip is latest)
ealias ve='python3.10 -m venv --clear --upgrade-deps'
ealias vedir='echo $VIRTUAL_ENV'
ealias veinit='python3.10 -m venv --clear --upgrade-deps .venv && vea' # PRN follow with pip install -r requirements.txt (if req file exists)
ealias veinitr='python3.10 -m venv --clear --upgrade-deps .venv && vea && pip3 install -r requirements.txt'
# PRN make install requirements.txt conditional on its presence in current dir => i.e. fish abbreviation + function
ealias veinitl='python3.10 -m venv --clear --upgrade-deps .venv.local && vea'

# manually activate/deactivate a venv, remember I have my autovenv plugin that will activate on cd
# FYI use activate.fish for fish (override is in python-specific.fish)
ealias vea='source .venv*/bin/activate' # .venv* allows for .venv or .venv.local (my two choices for venv names)
ealias ved='deactivate'

### pipx ###
ealias pipxi='pipx install'
ealias pipxir='pipx install -r requirements.txt'
ealias pipxip='pipx install --python'
ealias pipxls='pipx list'
ealias pipxrp='pipx runpip' # ie to install pypi deps (of primary command), i.e.:
#  pipx install ansible
#  pipx runpip ansible install toml  # add toml dependency, i.e. used by ansible-inventory --toml
ealias pipxr='pipx run' # think `npx foo`

### PIP ###
ealias pipls='pip3 list'
ealias piplo='pip3 list --outdated'

ealias pipir='pip3 install -r requirements.txt'
ealias pipi='pip3 install'

ealias pipup='pip3 install --upgrade '
ealias pipupp='pip3 install --upgrade pip'

# uninstall all packages:
ealias pipun='pip3 uninstall -y $(pip3 freeze)'
ealias pipunu='pip3 uninstall -y $(pip3 freeze --user)' # --user site (if applicable)
