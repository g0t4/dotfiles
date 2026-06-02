# XDG related configuration

# https://specifications.freedesktop.org/basedir/latest/

set -q XDG_STATE_HOME; or set -gx XDG_STATE_HOME "$HOME/.local/state"
# actions history (logs, history, recently used files, …)
# current state of the application that can be reused on a restart (view, layout, open files, undo history, …)

set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME "$HOME/.local/share"
# more important than STATE dir

# FYI this might break some existing config files that you rely on, if so just update and move them into this convention:
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME "$HOME/.config"
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME "$HOME/.cache"
# set -q XDG_RUNTIME_DIR; or set -gx XDG_RUNTIME_DIR "/run/user/(id -u)"

# ? add PATH like search env vars too?
#
# set -q XDG_DATA_DIRS; or set -gx XDG_DATA_DIRS "?"
# XDG_CONFIG_DIRS

# PRN Maybe redirect these:
# ## Common app env vars that should follow XDG
# set -q CARGO_HOME;        or set -gx CARGO_HOME "$XDG_DATA_HOME/cargo"
# set -q RUSTUP_HOME;       or set -gx RUSTUP_HOME "$XDG_DATA_HOME/rustup"
# set -q GOPATH;            or set -gx GOPATH "$XDG_DATA_HOME/go"
# set -q GNUPGHOME;         or set -gx GNUPGHOME "$XDG_DATA_HOME/gnupg"
# set -q NPM_CONFIG_USERCONFIG; or set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
# set -q NPM_CONFIG_CACHE;  or set -gx NPM_CONFIG_CACHE "$XDG_CACHE_HOME/npm"
# set -q PYTHON_HISTORY;    or set -gx PYTHON_HISTORY "$XDG_STATE_HOME/python/history"
# set -q SQLITE_HISTORY;    or set -gx SQLITE_HISTORY "$XDG_STATE_HOME/sqlite/history"
# set -q LESSHISTFILE;      or set -gx LESSHISTFILE "$XDG_STATE_HOME/less/history"
# set -q WGETRC;            or set -gx WGETRC "$XDG_CONFIG_HOME/wget/wgetrc"
# set -q INPUTRC;           or set -gx INPUTRC "$XDG_CONFIG_HOME/readline/inputrc"
#
# # Keep these out of $HOME when possible
# set -q NODE_REPL_HISTORY; or set -gx NODE_REPL_HISTORY "$XDG_STATE_HOME/node/repl_history"
# set -q PSQL_HISTORY;      or set -gx PSQL_HISTORY "$XDG_STATE_HOME/psql/history"
# set -q REDISCLI_HISTFILE; or set -gx REDISCLI_HISTFILE "$XDG_STATE_HOME/rediscli/history"
# set -q MYSQL_HISTFILE;    or set -gx MYSQL_HISTFILE "$XDG_STATE_HOME/mysql/history"
#
# # Create expected dirs
# mkdir -p \
#   "$XDG_CONFIG_HOME" \
#   "$XDG_CACHE_HOME" \
#   "$XDG_DATA_HOME" \
#   "$XDG_STATE_HOME" \
#   "$CARGO_HOME" \
#   "$RUSTUP_HOME" \
#   "$GOPATH" \
#   "$GNUPGHOME" \
#   (dirname "$NPM_CONFIG_USERCONFIG") \
#   "$NPM_CONFIG_CACHE" \
#   (dirname "$PYTHON_HISTORY") \
#   (dirname "$SQLITE_HISTORY") \
#   (dirname "$LESSHISTFILE") \
#   (dirname "$NODE_REPL_HISTORY") \
#   (dirname "$PSQL_HISTORY") \
#   (dirname "$REDISCLI_HISTFILE") \
#   (dirname "$MYSQL_HISTFILE")
#
