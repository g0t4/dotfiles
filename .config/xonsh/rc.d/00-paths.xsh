import os
import subprocess
import sys
from pathlib import Path

# ! 00- makes this run before auto-venv captures the PATH it later restores.

# FYI use manual PATH sync if this falls apart
#  you can manually sync a list of vars yourself (handle PATH type lists vs string values)
$UPDATE_OS_ENVIRON = True

# add lib dir to sys.path (early) => i.e. to locate my wes_logging python module
# => leave this here for other files (even if you aren't using logger currently)
XONSH_LIB = Path(__file__).parents[1] / "lib"
sys.path.insert(0, str(XONSH_LIB))
# TODO does xonsh have a packaging mechanism for my config, to handle relative imports within my "config package"

# from wes_logging import ensure_logger_is_setup, get_logger
# ensure_logger_is_setup()
# log = get_logger("path")

# from typing import Any
# from xonsh.events import events
#
# @events.on_envvar_change
# def on_env_updated(name: str, oldvalue: Any, newvalue: Any) -> None:
#     log.info(f"env_updated {name=} {oldvalue=} {newvalue=}")
#     # FYI w/o this os.getenv("PATH")/os.environ["PATH"] == '/usr/local/sbin:/usr/local/bin:/usr/bin'
#     # consequently, shutil.which("tool") returns nothing even when you fully setup $PATH and even when you can resolve commands just fine in subprocess mode!
#     # also python subprocess fails to find commands
#     # b/c python's PATH env var diverges from xonsh shell's $PATH changes
#     # they share a PATH value only when xonsh first starts but once my rc config files have run and changed env then the xonsh env variables differ
#     #
#     # next I'll try `$UPDATE_OS_ENVIRON = True` to keep full env in sync
#     if name == "PATH":
#         # one way sync XONSH $PATH => os.environ["PATH"]
#         os.environ["PATH"] = ":".join($PATH)

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
    current = list(@.env.get(name, []))
    current = [path for path in current if path not in paths]
    @.env[name] = list(paths) + current


if os.path.isfile("/opt/homebrew/bin/brew"):
    $HOMEBREW_PREFIX = "/opt/homebrew"
    $HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
    $HOMEBREW_REPOSITORY = "/opt/homebrew"
    _path_move_prepend("/opt/homebrew/bin", "/opt/homebrew/sbin")

    # This is the static equivalent of the remaining `brew shellenv` output.
    if @.env.get("MANPATH"):
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
