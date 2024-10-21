#!/usr/bin/env fish



# IIUC these don't have :CocInstall wrappers... instead just point to them directly?
echo "installing fish-lsp"
wcl ndonfris/fish-lsp
z ndonfris/fish-lsp
yarn install


# :CocInstall coc-markdownlint # todo vet this
