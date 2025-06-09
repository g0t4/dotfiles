#!/usr/bin/env fish

# NOTE: hack to start thinking about CM with dotfiles too w/o a bunch of overhead
# do not get into anything complicated here

function brew_install_if_missing

    # brew is ubiqutous and can install most apps
    # perhaps just call brew install every time and forget the performance hit?

    set cmd $argv[1]
    set pkg $argv[2]

    set -l fish_trace 1
    if command -v $cmd &>/dev/null
        echo "$cmd already installed"
        return
    end

    brew install $pkg

end

brew_install_if_missing fd fd
brew_install_if_missing ctags universal-ctags
