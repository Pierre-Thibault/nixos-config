# This is not a file using the Nix language so I can not define variables
# pierre-nixos must be changed manually.
{
  description = "My NixOS's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };
  outputs =
    { self, nixpkgs }:
    {
      nixosConfigurations.pierre-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./configuration.nix ];
      };
    };
}
