#!/usr/bin/env fish

# TODO alfred helpers script
function debug
    # redirect stdout to stderr for debugging in alfred
    echo "$argv" >&2
end


set first_path $argv[1]
debug "first_path: $first_path"
if test (count $argv) -gt 1
    debug "More than one path provided, only using first path: $first_path"
    debug "all: $argv"
end

set working_directory $first_path
if not test -d $working_directory
    set working_directory (dirname $first_path)
end
debug "working_directory: $working_directory"

# cd for `uv run` to work
cd $WES_DOTFILES/iterm2/alfred
uv run open_in_terminal.py $working_directory >&2
# >&2 redirs stdout to stderr (for alfred logging), otherwise stdout is swallowed up (only can see it if non-zero exit code and user prompts to see stdout)
