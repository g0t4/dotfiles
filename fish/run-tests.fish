#!/usr/bin/env fish

# ensure can run from anywhere
set script_path (status current-filename)
set script_dir (dirname $script_path)

fishtape $script_dir/functions/is_empty.fish

# PRN figure out what best way is to run all/some fish tests, maybe vscode test runner setup?
