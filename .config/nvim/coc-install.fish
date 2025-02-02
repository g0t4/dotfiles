#!/usr/bin/env fish



# IIUC these don't have :CocInstall wrappers... instead just point to them directly?
echo "installing fish-lsp"
wcl ndonfris/fish-lsp
z ndonfris/fish-lsp
yarn install


# :CocInstall coc-markdownlint # todo vet this

# for cmake-format, et al => https://cmake-format.readthedocs.io/en/latest/release_process.html
#   used by coc-cmake in nvim
pipx install cmakelang


# TODO move more here
