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
ln -f -s $dotfiles_dir/.config/hammerspoon/config ~/.hammerspoon/. # DIR SYMLINK

# ghostty
mkdir -p ~/.config/ghostty
ln -f -s $dotfiles_dir/.config/ghostty/config ~/.config/ghostty/.

# *** nvim ***
mkdir -p ~/.config/nvim
ln -f -s $dotfiles_dir/.config/nvim/init.lua ~/.config/nvim/init.lua
# FYI for directory symlinks, use only . on the end, else can end up with a symlink loop (nested symlink is created if exist already)
ln -f -s $dotfiles_dir/.config/nvim/lua ~/.config/nvim/. # DIR SYMLINK
ln -f -s $dotfiles_dir/.config/nvim/queries ~/.config/nvim/. # DIR SYMLINK
# ln -s $dotfiles_dir/.config/nvim/spell ~/.config/nvim/spell # PRN add this
ln -f -s $dotfiles_dir/.config/nvim/ftplugin ~/.config/nvim/. # DIR SYMLINK
ln -f -s $dotfiles_dir/.config/nvim/coc-settings.json ~/.config/nvim/coc-settings.json

# *** zed
mkdir -p ~/.config/zed
ln -f -s $dotfiles_dir/.config/zed/settings.json ~/.config/zed/settings.json

# *** bat
mkdir -p ~/.config/bat
ln -f -s $dotfiles_dir/.config/bat/config ~/.config/bat/config

# *** fish
if ! test -d ~/.config/fish
    echo "MISSING ~/.config/fish, do you have fish installed, not creating to avoid issues... create it and re-run this script"
else
    ln -f -s $dotfiles_dir/.config/fish/config.fish ~/.config/fish/config.fish
end
