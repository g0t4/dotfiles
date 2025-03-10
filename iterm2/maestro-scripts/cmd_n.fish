#!/opt/homebrew/bin/fish
# FYI do not use fish (i.e. "#!/usr/bin/env fish") command alone as its not in the path invoked by KMaestro
#   KMaestro silently fails if it cannot find the command too, very frustrating (in its Execute Shell Script action)

# cd to dir for two reasons:
#    1. so uv run finds venv
#    2. relative path for nvim.py
cd $WES_DOTFILES/iterm2/maestro-scripts
uv run cmd_n.py
if test $status -ne 0
    # return non-zero so I can trigger failure in python script and not need to set exit code here to get iterm to show the handler's debug output
    # don't need a message, that would come from python script
    exit 1
end
