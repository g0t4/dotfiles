#!/usr/bin/env fish

# new machine setup
# clone dotfiles
# install nvim
# links below (see dotfiles/install/symlinks.fish)
# install deps: npm/node, deno (markdown), rg (telescope), luarocks
# use `:checkhealth` in nvim to see whats missing
# careful, if build/run step on lazy plugin fails (i.e. peek md uses deno, another uses npm... if it fails I don't see a way to re-run it short of remove plugin's config and then Sync/Clean and then add back and try again... why does :Lazy not have a reinstall option?)
