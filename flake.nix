# This is not a file using the Nix language so I can not define variables
# pierre-nixos must be changed manually.
{
  description = "My NixOS's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };
  outputs =
    {
      nixpkgs,
      nix-flatpak,
      ...
    }:
    {
      nixosConfigurations.pierre-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./configuration.nix
        ];
      };
    };
}
