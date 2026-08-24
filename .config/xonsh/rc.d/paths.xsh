"""Environment and executable paths shared with fish/load_first/paths.fish."""

import os
import subprocess

# ! this must run early, including before auto-venv-on-cd b/c otherwise deactivate venv removes these PATH changes (reverts to PATH before venv was activated)

def _path_move_prepend(*paths):
    """Put existing directories at the front of PATH, without duplicates."""
    paths = [os.path.abspath(os.path.expanduser(path)) for path in paths]
    paths = [path for path in paths if os.path.isdir(path)]
    current = [path for path in $PATH if path not in paths]
    $PATH = paths + current


def _path_move_append(*paths):
    """Put existing directories at the end of PATH, without duplicates."""
    paths = [os.path.abspath(os.path.expanduser(path)) for path in paths]
    paths = [path for path in paths if os.path.isdir(path)]
    current = [path for path in $PATH if path not in paths]
    $PATH = current + paths


def _env_path_prepend(name, *paths):
    """Prepend unique entries to an EnvPath-style environment variable."""
    current = list(${...}.get(name, []))
    current = [path for path in current if path not in paths]
    ${...}[name] = list(paths) + current


if os.path.isfile("/opt/homebrew/bin/brew"):
    $HOMEBREW_PREFIX = "/opt/homebrew"
    $HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
    $HOMEBREW_REPOSITORY = "/opt/homebrew"
    _path_move_prepend("/opt/homebrew/bin", "/opt/homebrew/sbin")

    # This is the static equivalent of the remaining `brew shellenv` output.
    if ${...}.get("MANPATH"):
        manpath = list($MANPATH)
        if not manpath or manpath[0] != "":
            $MANPATH = [""] + manpath
    _env_path_prepend("INFOPATH", "/opt/homebrew/share/info")

elif os.path.isfile("/usr/local/bin/brew"):
    print("brew shellenv not implemented yet; add it if using an Intel Mac")


home = os.path.expanduser("~")

# These calls intentionally retain the order of paths.fish. Since each call
# moves its entry to the front, later entries have higher precedence.
for path in (

    # TODO look into what else is missing from /usr/libexec/path_helper after chsh
    # FYI... eval (/usr/libexec/path_helper -c)
    os.path.join("/usr/local/bin"),

    os.path.join(home, ".nix-profile/bin"),
    os.path.join(home, "bin"),
    os.path.join(home, "go/bin"),
    "/usr/local/go/bin",
    os.path.join(home, ".local/bin"),
    os.path.join(home, ".cargo/bin"),
    os.path.join(home, "repos/github/tree-sitter/tree-sitter/target/release"),
    os.path.join(home, "repos/github/ribru17/ts_query_ls/target/release"),
):
    _path_move_prepend(path)

# Preserve the Fish file's debug-directory test and release-directory PATH.
if os.path.isdir(os.path.join(home, "repos/github/zed-industries/zed/target/debug")):
    _path_move_prepend(
        os.path.join(home, "repos/github/zed-industries/zed/target/release")
    )

for path in (
    os.path.join(home, "repos/github/openai/codex/codex-rs/target/release"),
    os.path.join(home, "repos/github/ndonfris/fish-lsp/bin"),
    os.path.join(home, ".krew/bin"),
    "/snap/bin",
    os.path.join(home, ".dotnet/tools"),
    os.path.join(home, ".ghcup/bin"),
    "/opt/homebrew/opt/postgresql@17/bin",
    "/opt/homebrew/share/google-cloud-sdk/bin",
):
    _path_move_prepend(path)

llama_bin = os.path.join(home, "repos/github/ggml-org/llama.cpp/build/bin")
if os.path.isdir(llama_bin):
    _path_move_prepend(llama_bin)
    $GGUF_MODELS = os.path.join(home, "repos/github/ggml-org/llama.cpp/models")

for path in (
    "/opt/cuda/bin",
    os.path.join(home, ".npm-global/bin"),
):
    _path_move_prepend(path)

# Rancher Desktop was the sole append in paths.fish.
_path_move_append(os.path.join(home, ".rd/bin"))

if os.path.exists("/usr/lib/llvm-18/bin"):
    _path_move_prepend("/usr/lib/llvm-18/bin")


def use_brew_llvm():
    _path_move_prepend("/opt/homebrew/opt/llvm/bin")


def path_exists(path):
    return os.path.exists(os.path.expanduser(path))


def dir_exists(path):
    return os.path.isdir(os.path.expanduser(path))


def file_exists(path):
    return os.path.isfile(os.path.expanduser(path))


def symlink_exists(path):
    return os.path.islink(os.path.expanduser(path))


def _path_list_executables():
    """Print executable files and symlinks in each PATH directory via fd."""
    for directory in $PATH:
        if os.path.isdir(directory):
            subprocess.run(
                [
                    "fd",
                    "--type",
                    "executable",
                    "--type",
                    "symlink",
                    "--exact-depth",
                    "1",
                    ".",
                    directory,
                ],
                check=False,
            )


def _path_list():
    """Print everything immediately inside each PATH directory via fd."""
    for directory in $PATH:
        if os.path.isdir(directory):
            subprocess.run(
                ["fd", "--unrestricted", "--exact-depth", "1", ".", directory],
                check=False,
            )
