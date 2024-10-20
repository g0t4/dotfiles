#!/usr/bin/env bash

# new machine setup
# clone dotfiles
# install nvim
# links below
# install deps: npm/node, deno (markdown), rg (telescope), luarocks
# use `:checkhealth` in nvim to see whats missing


# current links I am using for vim dotfiles

# PRN wipe ~/.config/nvim if drastically change the links
# rm -rf ~/.config/nvim

mkdir -p ~/.config/nvim
ln -s $WES_DOTFILES/.config/nvim/init.lua ~/.config/nvim/init.lua 
ln -s $WES_DOTFILES/.config/nvim/lua ~/.config/nvim/lua

ln -s $WES_DOTFILES/.config/nvim/coc-settings.json ~/.config/nvim/coc-settings.json 
