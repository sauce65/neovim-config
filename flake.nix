{
  description = "Declarative NeoVim configuration as a home-manager module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    homeManagerModules = {
      neovim = import ./modules/neovim.nix;
      default = import ./modules/neovim.nix;
    };
  };
}
