#!/usr/bin/env fish

# start moving general symlinks to dotfiles here (consolidate them?)
ln -s ~/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/inputrc/.inputrc ~/.inputrc

# editline:
ln -s ~/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/editrc/.editrc ~/.editrc

# hammerspoon:
#
ln -s ~/repos/wes-config/wes-bootstrap/subs/dotfiles/.config/hammerspoon/init.lua ~/.hammerspoon/init.lua
