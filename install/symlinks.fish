#!/usr/bin/env fish

mkdir -p ~/.config

set -l dotfiles_dir ~/repos/github/g0t4/dotfiles
# start moving general symlinks to dotfiles here (consolidate them?)
ln -f -s $dotfiles_dir/.config/inputrc/.inputrc ~/.

# editline:
ln -f -s $dotfiles_dir/.config/editrc/.editrc ~/.

# hammerspoon:
#
mkdir -p ~/.hammerspoon
ln -f -s $dotfiles_dir/.config/hammerspoon/init.lua ~/.hammerspoon/.
ln -f -s $dotfiles_dir/.config/hammerspoon/config ~/.hammerspoon/.

# ghostty
mkdir -p ~/.config/ghostty
ln -f -s $dotfiles_dir/.config/ghostty/config ~/.config/ghostty/.
