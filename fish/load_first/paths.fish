# if not status is-login
#     return
# end

# ! this must run early, including before auto-venv-on-cd b/c otherwise deactivate venv removes these PATH changes (reverts to PATH before venv was activated)

# PRN if other scripts need HOMEBREW_PREFIX then move this earlier in startup scripts
# if homebrew is present, add env vars/PATH
if test -f /opt/homebrew/bin/brew
    # apple silicon macs

    # eval $(/opt/homebrew/bin/brew shellenv) # 30ms to run this so don't do it on every startup...
    # *** generated code:
    set --global --export HOMEBREW_PREFIX /opt/homebrew
    set --global --export HOMEBREW_CELLAR /opt/homebrew/Cellar
    set --global --export HOMEBREW_REPOSITORY /opt/homebrew
    fish_add_path --global --move --path /opt/homebrew/bin /opt/homebrew/sbin
    if test -n "$MANPATH[1]"
        set --global --export MANPATH '' $MANPATH
    end
    if not contains /opt/homebrew/share/info $INFOPATH
        set --global --export INFOPATH /opt/homebrew/share/info $INFOPATH
    end
    # *** end generated code

else if test -f /usr/local/bin/brew
    # intel macs
    #eval $(/usr/local/bin/brew shellenv)
    echo "brew shellenv not implemented yet, do this if you ever use an intel mac again"
end

if test -d "$HOME/bin"
    # fennel-ls
    # jattach
    fish_add_path --global --prepend "$HOME/bin"
end

if test -d "$HOME/go/bin"
    fish_add_path --global --prepend "$HOME/go/bin"
end

if test -d /usr/local/go/bin
    # from wget install (see fish/install/install.fish)
    fish_add_path --global --prepend "/usr/local/go/bin"
end

# FYI for now just make install it
# if test -d "$HOME/repos/github/neovim/neovim/build/bin"
#     export PATH="$HOME/repos/github/neovim/neovim/build/bin:$PATH"
# end

if test -d "$HOME/.local/bin"
    fish_add_path --global --prepend "$HOME/.local/bin"
end
if test -d "$HOME/.cargo/bin"
    fish_add_path --global --prepend "$HOME/.cargo/bin"
end

if test -d "$HOME/repos/github/tree-sitter/tree-sitter/target/release"
    fish_add_path --global --prepend "$HOME/repos/github/tree-sitter/tree-sitter/target/release"
end

if test -d "$HOME/repos/github/ribru17/ts_query_ls/target/release"
    fish_add_path --global --prepend "$HOME/repos/github/ribru17/ts_query_ls/target/release"
end

if test -d "$HOME/repos/github/zed-industries/zed/target/debug"
    fish_add_path --global --prepend "$HOME/repos/github/zed-industries/zed/target/release"
end

if test -d "$HOME/repos/github/openai/codex/codex-rs/target/release"
    # apply_patch tool, among others
    fish_add_path --global --prepend "$HOME/repos/github/openai/codex/codex-rs/target/release"
end

# fish-lsp (i.e. on arch)... brew on macOS
if test -d "$HOME/repos/github/ndonfris/fish-lsp/bin"
    fish_add_path --global --prepend "$HOME/repos/github/ndonfris/fish-lsp/bin"
end

# kubectl krew
if test -d "$HOME/.krew/bin"
    # suggested by krew:
    # set -q KREW_ROOT; and set -gx PATH $PATH $KREW_ROOT/.krew/bin; or set -gx PATH $PATH $HOME/.krew/bin

    # I will just go with ~/.krew/bin
    fish_add_path --global --prepend "$HOME/.krew/bin"
end

# /snap/bin (ubuntu/wsl)
if test -d /snap/bin
    fish_add_path --global --prepend "/snap/bin"
end

# ? fix ~/.dotnet/tools in path (replace with abs path) => see zshrc (ignore wrong path in /etc/paths.d/dotnet-cli-tools with ~/.dotnet/tools)
if test -d "$HOME/.dotnet/tools"
    # make dotnet tool install --global work (add to PATH)
    fish_add_path --global --prepend "$HOME/.dotnet/tools"
end

### COMPLETIONS path:
# TODO find a way to block bundled completions when they suck, like this one for curl:
#   trash /opt/homebrew/Cellar/fish/4.0.2/share/fish/completions/curl.fish
#   it is missing dozens of flags and yet...
#    for example: --fail-with-body
#   and yet the one from fuc works great (at least with missing options like --fail-with-body):
#     /Users/wesdemos/.cache/fish/generated_completions/curl.fish
#   for now I trashed the above one, but I should come up with a more viable approach
#    maybe symlink fuc ones to my completions dir or a second completions dir? OR just put all fuc ones in front of bundled completions?
#
#   for p in $fish_complete_path ; fd curl $p; end

function find_fish_completion_for_cmd_regex
    # usage:
    # find_fish_completion_for_cmd_regex "pgrep"
    # find_fish_completion_for_cmd_regex "pg.*"
    set cmd $argv[1]
    for dir in $fish_complete_path
        if not test -d $dir
            continue
        end

        fd --full-path completions/$cmd.fish $dir
    end
end
function list_terrible_completions_present
    echo "completions with issues in the past (empty list == good):"
    fd --full-path completions/curl.fish /opt/homebrew/Cellar/fish
    # TODO long term find a way around this issue... i.e. submit a patch to upstream or... put just this one from fuc ahead of bundled?
    # issue is the bundled ones should be superior to fuc generated ones...  so I cannot just put fuc first
    # by the way  fuc == fish_update_completions
end
if test -d $WES_DOTFILES/fish/completions/
    # - FYI autoloaded at Completion Time per command name (foo<TAB> loads foo.fish)
    # - Use for complex completions (i.e. ensure slow completions are lazy loaded)
    # - Use to override other completions
    # - Otherwise it's ok to inline completions (where command is defined)
    set fish_complete_path $fish_complete_path $WES_DOTFILES/fish/completions/
end

if test -d $WES_DOTFILES/fish/functions/
    # - FYI autoloaded when respective command name is first run (and periodically reloaded)
    set fish_function_path $fish_function_path $WES_DOTFILES/fish/functions/
end

# ghcup (haskell)
if test -d "$HOME/.ghcup/bin"
    fish_add_path --global --prepend "$HOME/.ghcup/bin"
    # FYI
    # ghcup list --tool ghc
    # ghcup set ghc latest/recommended
end

function use_brew_llvm
    fish_add_path --global --prepend "/opt/homebrew/opt/llvm/bin"
end

if test -d "/opt/homebrew/opt/postgresql@17/bin"
    # todo should I warn if newer or other version is installed instead?
    #  btw v14 is the "default" version in homebrew, why? why not v17?
    #  also if I use `brew link postgresql@17` it appends _17 on end of all commands which YUCK hence adding here:
    fish_add_path --global --prepend "/opt/homebrew/opt/postgresql@17/bin"
end

# google-cloud-sdk
if test -d /opt/homebrew/share/google-cloud-sdk/bin
    fish_add_path --global --prepend "/opt/homebrew/share/google-cloud-sdk/bin"
end

if test -d "$HOME/repos/github/ggml-org/llama.cpp/build/bin"
    # TODO is this what I want?
    fish_add_path --global --prepend "$HOME/repos/github/ggml-org/llama.cpp/build/bin"
    set GGUF_MODELS "$HOME/repos/github/ggml-org/llama.cpp/models"
end

# /opt/cuda/bin/
if test -d /opt/cuda/bin
    fish_add_path --global --prepend "/opt/cuda/bin"
end

# ~/.npm-global/bin
if test -d "$HOME/.npm-global/bin"
    fish_add_path --global --prepend "$HOME/.npm-global/bin"
end

# Rancher Desktop (IIGC created once user creates a cluster)
# ~/.rd/bin"
if test -d "$HOME/.rd/bin"
    fish_add_path --global --append "$HOME/.rd/bin"
end

# # * bash from source
# FYI has my fix for flickering abbr expansions... really only cared about it for recording purposes... don't need it if not demo'ing bash in a course (primary course topic too)
# if test -x $HOME/repos/github/g0t4/bash/bash
#     # annoying that bash doesn't build into a bin dir! puts root dir of repo into PATH (perhaps there is a build option for that...)
#     export PATH="$HOME/repos/github/g0t4/bash:$PATH"
# end

# *** PATH(s)
# I would prefer to house these under a command like `path exists` ... though fish has `path` command that would collide
#  think of these as an extension of fish's `path` command => new subcommands
function path_exists
    test -e $argv[1]
end
function dir_exists
    test -d $argv[1]
end
function file_exists
    test -f $argv[1]
end
function symlink_exists
    # not sure I like the name here but I do like dir_exists/file_exists above
    test -f $argv[1]
end

function _path_list_executables
    # usage:
    #   _path_list_executables | grep ans*
    for dir in $PATH
        if dir_exists $dir
            fd --type executable --type symlink --exact-depth 1 . $dir
            # FYI `--type executable` implies `--type file` (AND condition)
            # - thus symlinks to executables won't match
            #   i.e. fd ~/.rd/bin  => all symlinks+executable
            # - FIX => include both types `executable` and `symlink` (OR'd together)
        end
    end
end

function _path_list --description "everything in PATH directories"
    # don't filter files in path, return all of them
    for dir in $PATH
        if dir_exists $dir
            # fd provides file coloring based on type, etc
            fd --unrestricted --exact-depth 1 . $dir
        end
    end
end

# # /opt/watchman/bin/
# if test -d /opt/watchman/bin
#     export PATH="$PATH:/opt/watchman/bin"
# end

# PRN lm-studio
# set -gx PATH $PATH /Users/wesdemos/.cache/lm-studio/bin

# if llvm-18 present, use it, in future detect which version I want or set it per env?
#   FYI test -e takes 23us in fish on m1 mac so that is acceptable overhead for startup files
if test -e /usr/lib/llvm-18/bin/
    fish_add_path --global --prepend "/usr/lib/llvm-18/bin"
end
