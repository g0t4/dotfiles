#!/usr/bin/env fish

# new machine setup
# clone dotfiles
# install nvim
# links below
# install deps: npm/node, deno (markdown), rg (telescope), luarocks
# use `:checkhealth` in nvim to see whats missing
# careful, if build/run step on lazy plugin fails (i.e. peek md uses deno, another uses npm... if it fails I don't see a way to re-run it short of remove plugin's config and then Sync/Clean and then add back and try again... why does :Lazy not have a reinstall option?)


# current links I am using for vim dotfiles

# PRN wipe ~/.config/nvim if drastically change the links
# rm -rf ~/.config/nvim

mkdir -p ~/.config/nvim
ln -s $WES_DOTFILES/.config/nvim/init.lua ~/.config/nvim/init.lua
ln -s $WES_DOTFILES/.config/nvim/lua ~/.config/nvim/lua
ln -s $WES_DOTFILES/.config/nvim/queries ~/.config/nvim/queries  # for treesitter, and in my case to add highlighting on TODO comments, etc ...  alternative to syntax/regex matches
# ln -s $WES_DOTFILES/.config/nvim/spell ~/.config/nvim/spell # PRN add this
ln -s $WES_DOTFILES/.config/nvim/ftplugin ~/.config/nvim/ftplugin

ln -s $WES_DOTFILES/.config/nvim/coc-settings.json ~/.config/nvim/coc-settings.json
