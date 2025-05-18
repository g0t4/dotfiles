#!/usr/bin/env fish

mkdir -p $HOME/.config

set -l dotfiles_dir $HOME/repos/github/g0t4/dotfiles
# start moving general symlinks to dotfiles here (consolidate them?)
ln -f -s $dotfiles_dir/.config/inputrc/.inputrc $HOME/.

# editline:
ln -f -s $dotfiles_dir/.config/editrc/.editrc $HOME/.

if string match --quiet Darwin (uname -s)
    # *** macOS

    # hammerspoon:
    mkdir -p $HOME/.hammerspoon
    ln -f -s $dotfiles_dir/.config/hammerspoon/init.lua $HOME/.hammerspoon/.
    ln -f -s $dotfiles_dir/.config/hammerspoon/config $HOME/.hammerspoon/. # DIR SYMLINK

    # PRN add ghostty for any linux envs?
    # ghostty
    mkdir -p $HOME/.config/ghostty
    ln -f -s $dotfiles_dir/.config/ghostty/config $HOME/.config/ghostty/.

    # *** iterm2 scripts dir
    if ! test -d $HOME/Library/Application\ Support/iTerm2/Scripts
        echo "MISSING $HOME/Library/Application\ Support/iTerm2/Scripts, do you have iTerm2 installed, not creating to avoid issues... create it and re-run this script"
    else
        # -n means don't follow target symlink (else recreates nested symlink)
        ln -f -n -s $dotfiles_dir/iterm2/scripts/ $HOME/Library/Application\ Support/iTerm2/Scripts
    end

end

# *** nvim ***
if command -q nvim
    mkdir -p $HOME/.config/nvim
    ln -f -s $dotfiles_dir/.config/nvim/init.lua $HOME/.config/nvim/init.lua
    # FYI for directory symlinks, use only . on the end, else can end up with a symlink loop (nested symlink is created if exist already)
    ln -f -s $dotfiles_dir/.config/nvim/lua $HOME/.config/nvim/. # DIR SYMLINK
    ln -f -s $dotfiles_dir/.config/nvim/fnl $HOME/.config/nvim/. # DIR SYMLINK
    ln -f -s $dotfiles_dir/.config/nvim/queries $HOME/.config/nvim/. # DIR SYMLINK
    # ln -s $dotfiles_dir/.config/nvim/spell $HOME/.config/nvim/spell # PRN add this
    ln -f -s $dotfiles_dir/.config/nvim/ftplugin $HOME/.config/nvim/. # DIR SYMLINK
    ln -f -s $dotfiles_dir/.config/nvim/after $HOME/.config/nvim/. # DIR SYMLINK
    ln -f -s $dotfiles_dir/.config/nvim/coc-settings.json $HOME/.config/nvim/coc-settings.json
    ln -f -s $dotfiles_dir/.config/nvim/snippets $HOME/.config/nvim/. # DIR SYMLINK
end
#
# FYI no longer using vimrc, but I might want it back for some envs?
# $HOME/.vimrc

# *** zed
if command -q zed
    mkdir -p $HOME/.config/zed
    ln -f -s $dotfiles_dir/.config/zed/settings.json $HOME/.config/zed/settings.json
end

# *** bat
mkdir -p $HOME/.config/bat
ln -f -s $dotfiles_dir/.config/bat/config $HOME/.config/bat/config

# *** fish
if ! test -d $HOME/.config/fish
    echo "MISSING $HOME/.config/fish, do you have fish installed, not creating to avoid issues... create it and re-run this script"
else
    ln -f -s $dotfiles_dir/fish/config/config.fish $HOME/.config/fish/.
end

# *** grc
ln -f -s $dotfiles_dir/.grc $HOME/. # DIR SYMLINK

# *** git ***
mkdir -p $HOME/.config/git
ln -f -s $dotfiles_dir/.config/git/ignore $HOME/.config/git/.
if string match --quiet Linux (uname -s)
    ln -s $HOME/repos/github/g0t4/dotfiles/git/linux.gitconfig $HOME/.gitconfig
end

# *** hushlogin
touch $HOME/.hushlogin

if test -d $HOME/.ipython
    mkdir -p $HOME/.ipython/profile_default
    ln -f -s $dotfiles_dir/.ipython/profile_default/ipython_config.py $HOME/.ipython/profile_default/.
    ln -f -s $dotfiles_dir/.ipython/profile_default/ipython_kernel_config.py $HOME/.ipython/profile_default/.
end

# *** uv.toml
mkdir -p $HOME/.config/uv
ln -f -s $dotfiles_dir/.config/uv/uv.toml $HOME/.config/uv/.

# *** fd command
mkdir -p $HOME/.config/fd
ln -f -s $dotfiles_dir/.config/fd/ignore $HOME/.config/fd/.

