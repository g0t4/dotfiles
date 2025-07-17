# COMPLETIONS - zsh bundles _pip/_python completions
#  - pro: zsh pip completions work on package names! cursory testing of pip/python native completions indicates they don't support package names...
#    - complete pkg names way more valuable
#  - con: OOB zsh completions are not complete arg wise and I'm not sure how often they are updated... I should familiarize myself with making a contrib for this (I saw that github clone of zsh supports completion contribs... sounds like listserve is where most do it)

# * profiling
abbr py_profile_import_time PYTHONPROFILEIMPORTTIME=1 python -c "from sentence_transformers import SentenceTransformer"

# why `command` => `command3`?
#   i.e. pip => pip3, python => python3
#   global interpreter => command3 is ubiquitous AND recommended (for the default 3.X version)
#   venv => command3 defined (for all v3 venvs!)
#
# ipython repl is FAR superior in terms of colors and other features
abbr ipy ipython3
abbr py ipython3
# make python ONE more char longer than ipython py abbr, but don't make it so I have to type full thing or tab complete it
abbr pyt python3
abbr pyth python3
abbr pytho python3
abbr python python3
# abbr pym python3 -m
abbr pip pip3
#
# attempt to target REPLs that aren't responding to Ctrl+D (nor typing)... usually are latest version which is 3.13.5 currently
#   PRN - do not have "iterm" in the command args
abbr py_pgrep 'pgrep -lf "python.*3.13.5"'
abbr py_kill 'pkill -ilf "python.*3.13.5"'

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
#
# FYI cannot configure no-description/readme by default, so just use them here in my abbr instead
#   unfortunately I cannot tell it no hello.py too
abbr uvi_bootstrap 'uv init --no-description --no-readme && uv add yapf rope ipython rich' # bootstrap my preferred deps (i.e. formatter, ipython REPL)... things I inevitably add to all my python projects
#   todo add `ipykernel` or `ipython` to all projects too? I like to run code adhoc in nvim with iron.nvim, that requires ipython at a minimum
#   also I prefer the ipython REPL over python's builtin REPL
abbr uvi 'uv init --no-description --no-readme'
# ipykernel is for ipython
abbr uvi_common 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx'
abbr uvi_cli 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx typer'
abbr uvi_web 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx fastapi'
#
abbr uvp 'uv pip'
abbr uvpi 'uv pip install'
abbr uvpie 'uv pip install --editable .'
abbr uvpir 'uv pip install -r requirements.txt'
abbr uvls 'uv pip list' # or do I want `uv tree` here?.... what else would I do with `uv list == uvl` basically?
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

abbr uv_build 'uv build --no-sources' # TODO do I want --no-sources? by default
abbr uv_publish 'uv publish'
abbr uv_clean 'uv clean'

function detect_encoding
    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/detect_encoding.py"
    $_python3 $_script_py $argv
end

function rag_indexer
    set ASK_REPO "$HOME/repos/github/g0t4/ask-openai.nvim"
    set _python3 "$ASK_REPO/.venv/bin/python3"
    set _script_py "$ASK_REPO/lua/ask-openai/rag/indexer.py"
    $_python3 $_script_py $argv
end

abbr rag_rebuilder 'rag_indexer --rebuild'

# *** wcl wrappers
function wcl
    if test -t 1
        # TODO remove this when course is done
        # only warn if using directly, don't mess up z command that uses this
        log_ --red --bold "this is NOT wcl from course files, just heads up in case you use the wrong one habitually"
    end

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
