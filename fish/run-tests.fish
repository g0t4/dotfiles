#!/usr/bin/env fish

# ensure can run from anywhere
set script_path (status current-filename)
set script_dir (dirname $script_path)

fishtape $script_dir/functions/is_empty.fish

# PRN figure out what best way is to run all/some fish tests, maybe vscode test runner setup?


# TODO put tests here for cd to files... do it later, I can't inline those b/c cd can't be subshelled, unless maybe I call fish -c "fishtape ... whatever"... 
# fishtape $script_dir/load_last/files-specific.fish