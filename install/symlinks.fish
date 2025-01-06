#!/usr/bin/env fish

mkdir -p ~/.config

# start moving general symlinks to dotfiles here (consolidate them?)
ln -s ~/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/inputrc/.inputrc ~/.

# editline:
ln -s ~/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/editrc/.editrc ~/.

# hammerspoon:
#
mkdir -p ~/.hammerspoon
ln -s ~/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/hammerspoon/init.lua ~/.hammerspoon/.
ln -s ~/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/hammerspoon/config ~/.hammerspoon/.

# ghostty
mkdir -p ~/.config/ghostty
ln -s ~/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/ghostty/config ~/.config/ghostty/.
