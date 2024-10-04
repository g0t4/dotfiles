# COMPLETIONS - zsh bundles _pip/_python completions
#  - pro: zsh pip completions work on package names! cursory testing of pip/python native completions indicates they don't support package names...
#    - complete pkg names way more valuable
#  - con: OOB zsh completions are not complete arg wise and I'm not sure how often they are updated... I should familiarize myself with making a contrib for this (I saw that github clone of zsh supports completion contribs... sounds like listserve is where most do it)

# why `command` => `command3`?
#   i.e. pip => pip3, python => python3
#   global interpreter => command3 is ubiquitous AND recommended (for the default 3.X version)
#   venv => command3 defined (for all v3 venvs!)
abbr py python3
abbr python python3
abbr pip pip3
abbr pydoc pydoc3
abbr python-config python3-config

# PRN go back to python3.10/11 etc in ve* abbrs?
### VENV (--clear allows to recreate venv if already dir exists, --upgrade-deps makes sure pip is latest)
abbr ve 'python3 -m venv --clear --upgrade-deps'
abbr vedir 'echo $VIRTUAL_ENV'
#
abbr --function veinit_func --add veinit
function veinit_func

    # legacy abbr's
    # abbr veinit 'python3 -m venv --clear --upgrade-deps .venv && source .venv*/bin/activate.fish && touch requirements.txt' # PRN follow with pip install -r requirements.txt (if req file exists)
    # abbr veinitr 'python3 -m venv --clear --upgrade-deps .venv && source .venv*/bin/activate.fish && pip3 install -r requirements.txt'

    # TODO pass arg for python version? 3.11, 3.10, etc
    set py_version 3
    echo -n "python$py_version -m venv --clear --upgrade-deps .venv && source .venv*/bin/activate.fish"
    if test -f requirements.txt
        # PRN search for requirements up to root repo dir? not sure I have a need for this though, so wait for now
        echo -n " && pip3 install -r requirements.txt"
    else
        echo -n " && touch requirements.txt"
    end
end
abbr veinitl 'python3 -m venv --clear --upgrade-deps .venv.local && vea'
# PRN veinitl w/ veinitl_func like veinit_func

# manually activate/deactivate a venv, remember I have my autovenv plugin that will activate on cd
# FYI use activate.fish for fish (override is in python-specific.fish)
abbr ved deactivate
abbr vea 'source .venv*/bin/activate.fish' # override zsh version's /activate
# add function so this can be embedded in other abbr expansions
function vea --wraps=source
    source .venv*/bin/activate.fish
end


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

function wcl

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/wcl.py"

    $_python3 $_script_py $argv

end

# completions:
complete -c wcl --no-files
complete -c wcl --long-option path-only --description 'Only print the path'
complete -c wcl --long-option dry-run
# complete my repository names:
# gh api /users/g0t4/repos --jq '.[].name' # later use .full_name for other org repos?
complete -c wcl -a '(gh repo list --json name --jq .[].name --limit 1000)' -f

# PRN complete with gh repo list... with my repos
# complete -c wcl -a '(gh repo list --json nameWithOwner --jq .[].nameWithOwner --limit 1000)'

function wrc

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/wrc.py"

    $_python3 $_script_py $argv

end

# *** wcl wrappers
function wcl

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/wcl.py"

    $_python3 $_script_py $argv

end

# completions:
complete -c wcl --no-files
complete -c wcl --long-option path-only --description 'Only print the path'
complete -c wcl --long-option dry-run
# complete my repository names:
# gh api /users/g0t4/repos --jq '.[].name' # later use .full_name for other org repos?
complete -c wcl -a '(gh repo list --json name --jq .[].name --limit 1000)' -f

# PRN complete with gh repo list... with my repos
# complete -c wcl -a '(gh repo list --json nameWithOwner --jq .[].nameWithOwner --limit 1000)'

function wrc

    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/wrc.py"

    $_python3 $_script_py $argv

end
