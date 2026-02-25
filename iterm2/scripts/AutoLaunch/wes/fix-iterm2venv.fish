#!/usr/bin/env fish -i

# available versions are in here:
set iterm2_app_support "$HOME/Library/Application Support/iTerm2"
# NOTE each iterm2env-... dir appears to be a PYENV_ROOT w/ multiple python versions in versions/ dir

set master "$HOME/Library/Application Support/iTerm2/iterm2env-3.10.4"
if test -d $master
    rich --print "[bold blue]## FOUND master: $master"
else
    rich --print "[bold red]## Missing master iterm2env copy, is there a newer version in $iterm2_app_support:"
    fd iterm2env $iterm2_app_support --max-depth 1 | string_indent
    return 1
end

set target "$HOME/repos/github/g0t4/dotfiles/iterm2/scripts/AutoLaunch/wes/iterm2env"
if test -d $target
    rich --print "[bold blue]## TARGET EXISTS, removing $target"
    trash $target
end

rich --print "[bold blue]## COPYING iterm2env..."
# TODO consolidate rule of thumb for / on end
cp -r "$HOME/Library/Application Support/iTerm2/iterm2env-3.10.4" \
    "$HOME/repos/github/g0t4/dotfiles/iterm2/scripts/AutoLaunch/wes/iterm2env"
# FYI should be able to restart script now and only be missing rich/openai packages

# * packages
cd "$HOME/repos/github/g0t4/dotfiles/iterm2/scripts/AutoLaunch/wes"
rich --print "[bold blue]## pip list..."
iterm2env/versions/3.10.4/bin/python3 -m pip list

rich --print "[bold blue]## pip installs..."
iterm2env/versions/3.10.4/bin/python3 -m pip install rich
iterm2env/versions/3.10.4/bin/python3 -m pip install openai
iterm2env/versions/3.10.4/bin/python3 -m pip install langchain-openai
