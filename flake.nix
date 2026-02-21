# This is not a file using the Nix language so I can not define variables
# pierre-nixos must be changed manually.
{
  description = "My NixOS's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-25-05.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-25-05,
      nix-flatpak,
      nixpkgs-unstable,
      ...
    }:
    {
      nixosConfigurations.pierre-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./configuration.nix
        ];
        specialArgs = {
          unstable = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          nixos-25-05 = import nixpkgs-25-05 {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
      };
    };
}
