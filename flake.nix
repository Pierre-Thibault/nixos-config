# This is not a file using the Nix language so I can not define variables
# pierre-nixos must be changed manually.
{
  description = "My NixOS's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nvf.url = "github:notashelf/nvf"; # Neovim configuration
  };
  outputs =
    {
      nixpkgs,
      nix-flatpak,
      nvf,
      ...
    }:
    {
      nixosConfigurations.pierre-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          nvf.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
