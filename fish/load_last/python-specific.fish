# COMPLETIONS - zsh bundles _pip/_python completions
#  - pro: zsh pip completions work on package names! cursory testing of pip/python native completions indicates they don't support package names...
#    - complete pkg names way more valuable
#  - con: OOB zsh completions are not complete arg wise and I'm not sure how often they are updated... I should familiarize myself with making a contrib for this (I saw that github clone of zsh supports completion contribs... sounds like listserve is where most do it)

# why `command` => `command3`?
#   i.e. pip => pip3, python => python3
#   global interpreter => command3 is ubiquitous AND recommended (for the default 3.X version)
#   venv => command3 defined (for all v3 venvs!)
abbr py ipython3
abbr python ipython3
abbr pip pip3

# PRN go back to python3.10/11 etc in ve* abbrs?
### VENV (--clear allows to recreate venv if already dir exists, --upgrade-deps makes sure pip is latest)
abbr ve 'ipython3 -m venv --clear --upgrade-deps'
abbr vedir 'echo $VIRTUAL_ENV'

function relative_path
    # doesn't have to be real paths

    set -l from $argv[1]
    set -l to $argv[2]
    python3 -c "import os; print(os.path.relpath('$to', '$from'))"

    # Example usage:
    #relative_path /home/user/project "/home/user/project/docs/file.txt"
end

abbr ves venv_status
function venv_status
    if test -n "$VIRTUAL_ENV"
        echo -n -s (set_color cyan) \ue73c (set_color normal) " "
    else
        return
    end
    # show how high up the venv_dir is vs current_dir
    relative_path (pwd) $VIRTUAL_ENV
end
#
abbr veinit 'uv venv'
abbr veinit12 'uv venv --python 3.12' # good reminder to replace w/ whatever version I need

# manually activate/deactivate a venv, remember I have my autovenv plugin that will activate on cd
# FYI use activate.fish for fish (override is in python-specific.fish)
abbr ved deactivate
abbr vea 'source .venv*/bin/activate.fish' # override zsh version's /activate

# !!! GO COLD TURKEY TO TRY uv command and update all venvs to use it, best way to see what I think of it and learn it... so stop using pip directly (unless uv doesn't work for my projects)
abbr pipir "uv add -r requirements.txt && rm requirements.txt # REMINDER TO MIGRATE to pyproject.toml + uv"
#   pipir is just for muscle memory b/c I used it to `pip install -r requirements.txt` previously

abbr uva 'uv add'
#
# TODO review new set of uv commands (read a bit more to verify I understand them):
# lockfile/dependency related:
abbr uvau 'uv add --upgrade' # all upgrade on all packages (within existing constraint in pyproject.toml)
abbr uvaup 'uv add --upgrade-package' # upgrade specific package
# just edit the pyproject.toml to change the constraint (not sure if there is a command to update the constraint, nor should there be?)
# lock docs: https://docs.astral.sh/uv/concepts/projects/sync/
abbr uvl 'uv lock' # create lock file (also sync does this, as well as many other commands: tree, run, etc)
abbr uvlu 'uv lock --upgrade'
abbr uvlup 'uv lock --upgrade-package' # <package==version> upgrade just one package
abbr uvlc 'uv lock --check' # check if lock is up to date
abbr uvs 'uv sync'
# optional deps (extras):
#   https://docs.astral.sh/uv/concepts/projects/dependencies/#optional-dependencies
abbr uvsa 'uv sync --all-extras' # sync al extras packages
abbr uvse 'uv sync --extra' # <pkg> sync specific extras package
# TODO end review here
#
abbr uvrm 'uv remove'
abbr uvr 'uv run'
abbr uvt 'uv tree'
abbr uvtree 'uv tree --outdated'
abbr uvv 'uv venv'
abbr uvi 'uv init'
#
abbr uvp 'uv pip'
abbr uvpi 'uv pip install'
abbr uvpir 'uv pip install -r requirements.txt'
abbr uvpls 'uv pip list'
abbr uvplo 'uv pip list --outdated'
# TODO add back other pip commands as `uv pip` commands now that I wrapped my mind around using uv for my projects and not for other projects that are just using requirements.txt
#
abbr uvpy 'uv python list' # list installed python versions
#
# `uv tool install` is a replacement for `pipx install` (IIUC)
abbr uvt 'uv tool'
abbr uvtr 'uv tool run'
#abbr uvtd 'uv tool dir'
#   uv tool dir --bin # ~/.local/bin (many apps use this)
abbr uvtr 'uv tool list'
abbr uvti 'uv tool install'
#abbr uvtu 'uv tool upgarde'
#abbr uvtun 'uv tool uninstall'
abbr uvx 'uv tool run' # uvx is an alias for `uv tool run`
#
# *** OMG it can install python versions (like pyenv)
#  mostly reminders for now:
abbr uvpy 'uv python list'
#abbr uvpyi 'uv python install'
# FYI just put .python-version file in repo and run `uv venv` and it will install the version (if needed!)





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
