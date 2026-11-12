#!/usr/bin/env fish

nix profile add nixpkgs#nixd
nix profile add nixpkgs#neovim

# to install my flake
nix profile upgrade nix/mac
