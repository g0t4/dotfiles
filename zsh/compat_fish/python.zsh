# COMPLETIONS - zsh bundles _pip/_python completions
#  - pro: zsh pip completions work on package names! cursory testing of pip/python native completions indicates they don't support package names...
#    - complete pkg names way more valuable
#  - con: OOB zsh completions are not complete arg wise and I'm not sure how often they are updated... I should familiarize myself with making a contrib for this (I saw that github clone of zsh supports completion contribs... sounds like listserve is where most do it)

# why `command` => `command3`?
#   i.e. pip => pip3, python => python3
#   global interpreter => command3 is ubiquitous AND recommended (for the default 3.X version)
#   venv => command3 defined (for all v3 venvs!)
eabbr python 'python3'
eabbr py 'python3'
eabbr pip 'pip3'
eabbr pydoc 'pydoc3'
eabbr python-config 'python3-config'

### VENV (--clear allows to recreate venv if already dir exists, --upgrade-deps makes sure pip is latest)
eabbr ve 'python3.10 -m venv --clear --upgrade-deps'
eabbr vedir 'echo $VIRTUAL_ENV'
eabbr veinit 'python3.10 -m venv --clear --upgrade-deps .venv && vea' # PRN follow with pip install -r requirements.txt (if req file exists)
eabbr veinitr 'python3.10 -m venv --clear --upgrade-deps .venv && vea && pip3 install -r requirements.txt'
# PRN make install requirements.txt conditional on its presence in current dir => i.e. fish abbreviation + function
eabbr veinitl 'python3.10 -m venv --clear --upgrade-deps .venv.local && vea'

# manually activate/deactivate a venv, remember I have my autovenv plugin that will activate on cd
# FYI use activate.fish for fish (override is in python-specific.fish)
# FYI vea is shell specific
eabbr ved 'deactivate'

### pipx ###
eabbr pipxi 'pipx install'
eabbr pipxir 'pipx install -r requirements.txt'
eabbr pipxip 'pipx install --python'
eabbr pipxls 'pipx list'
eabbr pipxrp 'pipx runpip' # ie to install pypi deps (of primary command), i.e.:
#  pipx install ansible
#  pipx runpip ansible install toml  # add toml dependency, i.e. used by ansible-inventory --toml
eabbr pipxr 'pipx run' # think `npx foo`

### PIP ###
eabbr pipls 'pip3 list'
eabbr piplo 'pip3 list --outdated'

eabbr pipir 'pip3 install -r requirements.txt'
eabbr pipi 'pip3 install'

eabbr pipup 'pip3 install --upgrade '
eabbr pipupp 'pip3 install --upgrade pip'

# uninstall all packages:
eabbr pipun 'pip3 uninstall -y $(pip3 freeze)'
eabbr pipunu 'pip3 uninstall -y $(pip3 freeze --user)' # --user site (if applicable)
