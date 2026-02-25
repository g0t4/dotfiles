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

abbr pipir "uv add -r requirements.txt && rm requirements.txt # REMINDER TO MIGRATE to pyproject.toml + uv"
#
abbr uva uv_add
function uv_add
    if not _repo_is_index_clean
        # need to stage package* hence check nothing else is staged
        # TODO can I just commit with explicit files instead and ignore stage?
        log_ --red "cannot uv add w/ outstanding staged (index) changes, aborting..."
        return 1
    end
    if not test -f pyproject.toml
        log_ --red "pyproject.toml not found in current directory, aborting..."
        return 1
    end
    uv add $argv
    git commit -m "uv add $argv" pyproject.toml uv.lock
end
#
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

abbr uvrm uv_remove
function uv_remove
    if not _repo_is_index_clean
        log_ --red "cannot uv remove w/ outstanding staged (index) changes, aborting..."
        return 1
    end
    if not test -f pyproject.toml
        log_ --red "pyproject.toml not found in current directory, aborting..."
        return 1
    end
    uv remove $argv
    git commit -m "uv remove $argv" pyproject.toml uv.lock
end

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
abbr uvinw 'uv init --no-description --no-readme --no-workspace'
# ipykernel is for ipython
abbr uvi_common 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx'
abbr uvi_cli 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx typer'
abbr uvi_web 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx fastapi'
#
abbr uvp 'uv pip'
abbr uvpi 'uv pip install'
abbr uvpie 'uv pip install --editable .'
abbr uvpir 'uv pip install -r requirements.txt'
abbr uv_pip_install_upgrade 'uv pip install --upgrade $(uv pip list --outdated | tail +3 | cut -d' ' -f1)'
abbr uvls 'uv pip list' # or do I want `uv tree` here?.... what else would I do with `uv list == uvl` basically?
abbr uvpls 'uv pip list'
abbr uvplo 'uv pip list --outdated'
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

abbr uv_build 'uv build --no-sources'
abbr uv_publish 'uv publish'
abbr uv_clean 'uv clean'

function pstree_grep
    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/pstree_grep.py"
    $_python3 $_script_py $argv
end

function detect_encoding
    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    set -l _script_py "$WES_DOTFILES/zsh/compat_fish/pythons/detect_encoding.py"
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

function rich_colors
    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    $_python3 -m rich.color
end

function matplotlib_colors
    set -l _python3 "$WES_DOTFILES/.venv/bin/python3"
    begin
        head -76 "$WES_REPOS/github/matplotlib/matplotlib/galleries/examples/color/named_colors.py"
        echo "plot_colortable(mcolors.CSS4_COLORS); plt.show()"
    end | $_python3
end

if status is-interactive
    # FYI I setup codex's codex-rs in my PATH to use its apply_patch standalone command

    function apply_patch_multi
        # use venv of gpt-oss repo
        set -l repo $WES_REPOS/github/g0t4/ask-openai.nvim
        set -l script $repo/lua/ask-openai/tools/inproc/apply_patch_multi.py
        set -l py $repo/.venv/bin/python3

        if not isatty stdin
            $py $script $argv
            return
        end

        echo "You must provide a patch file either via STDIN"
        echo "   cat add-file.patch | apply_patch"
    end
end

# * ptw
abbr --set-cursor -- ptw_logs 'ptw --clear *%_tests.py -- --capture=no --log-cli-level=INFO'
# setup % so I can easily change matching python code files for tests to run
# ptw args:
#   --clear == clear screen b/w runs
# pytest args:
#   --capture=no          see print() output (don't capture STDOUT)
#   --log-cli-level=INFO
#   --durations=N         Show N slowest setup/test durations (N=0 for all)
#   --durations-min=N     Minimal duration in seconds for inclusion in slowest list. Default: 0.005 (or 0.0 if -vv is given).
#
abbr --set-cursor ptw_one --function __ptw_one
function __ptw_one

    # default example (can override with local .config.fish example)
    set ptw_file_watch_glob '*%_tests.py'
    set test_case 'path/to/foo_tests.py::UnitTests::test_so_and_so'

    if functions -q __local_ptw_one
        # run the local function and capture its output
        set output (__local_ptw_one)
        # split the output into two variables using space as delimiter
        set ptw_file_watch_glob (string split ' ' $output)[1]
        set test_case (string split ' ' $output)[2]
    end

    # FYI leave ptw_file_watch_glob unwrapped (shell glob)
    echo "ptw --clear $ptw_file_watch_glob -- '$test_case%' --capture=no --log-cli-level=INFO"
    # % is for cursor placement, now that this can have local overrides, probably most likely place to make changes is the one test case to run, and not the files to monitor for changes

end
