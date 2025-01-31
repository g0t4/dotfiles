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
abbr pipls "uv tree"
abbr piplo "uv tree --outdated"
abbr pipir "uv add -r requirements.txt && rm requirements.txt # REMINDER TO MIGRATE to pyproject.toml + uv"
# later => after I convert most of my projects => switch pipir => uvar abbr
#   pipir is just for muscle memory b/c I used it to `pip install -r requirements.txt` previously


abbr uva 'uv add'
abbr uvrm 'uv remove'
abbr uvs 'uv sync'
abbr uvr 'uv run'
abbr uvt 'uv tree'
abbr uvtree 'uv tree --outdated'
abbr uvv 'uv venv'
abbr uvp 'uv pip'
abbr uvi 'uv init'
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
