#!/usr/bin/env fish

function debug
    # redirect stdout to stderr for debugging in alfred
    echo "$argv" >&2
end


set first_path $argv[1]
debug "first_path: $first_path"
debug "all: $argv"

# nvim.fish will handle finding repo root so just pass dir of file (or dir itself) as working directory
set working_directory $first_path
if not test -d $working_directory
    set working_directory (dirname $first_path)
end

debug "working_directory: $working_directory"

# FYI nvim.fish is my iterm2 semantic click handler, so I am calling it too and passing args to have it open files as if clicked in iterm but from Finder
set nvim_fish_path $WES_DOTFILES/iterm2/semantic-click-handler/nvim.fish
"$nvim_fish_path" \
    $first_path \
    "" "" "" \
    $working_directory \
    "alfred-open-with"
# FYI alfred-open-with is a hack to open dirs in nvim too when passed from just this script (not in iterm2 semantic click handler)
