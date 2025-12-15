# This is not a file using the Nix language so I can not define variables
# pierre-nixos must be changed manually.
{
  description = "My NixOS's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    # espanso-fix.url = "github:pitkling/nixpkgs/espanso-fix-capabilities-export";
  };
  outputs =
    {
      nixpkgs,
      nix-flatpak,
      nixpkgs-unstable,
      # espanso-fix,
      ...
    }:
    {
      nixosConfigurations.pierre-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          # espanso-fix.nixosModules.espanso-capdacoverride
          ./configuration.nix
        ];
        specialArgs = {
          unstable = import nixpkgs-unstable { system = "x86_64-linux"; };
        };
      };
    };
}
