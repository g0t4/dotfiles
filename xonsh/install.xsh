#!/usr/bin/env xonsh

# FYI ~/.config/xonsh/rc.d is in this dotfiles repo

# https://iterm2.com/shell_integration/xonsh  # FYI this did not work as listed on https://iterm2.com/documentation-shell-integration.html so I went to the repo instead:
curl -L \
    https://raw.githubusercontent.com/gnachman/iTerm2-shell-integration/refs/heads/main/shell_integration/xonsh \
    -o ~/.config/xonsh/rc.d/iterm2.xsh

# TODO make sure to install bash-completion pkg (on arch for sure) to get this to then work with xonsh completions for hf CLI:
# works as of 1.31
mkdir -p ~/.bash_completions
bash -c " _HF_COMPLETE=bash_source hf > ~/.bash_completions/hf.sh"
