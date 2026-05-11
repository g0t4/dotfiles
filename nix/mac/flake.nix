{
  description = "Wes dev environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin"; # Apple Silicon
      pkgs = import nixpkgs { inherit system; };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      # TODO find more packages to manage with nix
      # TODO setup nix on arch too?
      packages.${system}.default = pkgs.buildEnv {
        name = "wes-tools";
        paths = [
          pkgs.difftastic
          pkgs.fd
          pkgs.ripgrep
          pkgs.fzf
          pkgs.bat
          pkgs.eza
          pkgs.jq
          pkgs.yq
          pkgs.hyperfine
          pkgs.difftastic
          pkgs.delta
          pkgs.httpie
          pkgs.glow
          pkgs.tmux
          pkgs.zellij
          pkgs.shellcheck
          pkgs.shfmt
          pkgs.lua-language-server
          pkgs.tree-sitter
          # infrastructure for editing flakes (etc):
          pkgs.nixfmt # nix fmt fails for formatting currently with coc... doc is wiped (server says to erase entire doc on format so likely `nix fmt` is not outputing the updated document over STDOUT ... likely need to pass different args to fix?
          pkgs.nix
        ];
      };
    };
}
