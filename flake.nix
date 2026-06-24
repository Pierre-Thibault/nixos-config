# This is not a file using the Nix language so I can not define variables
# pierre-nixos must be changed manually.
{
  description = "My NixOS's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nix-flatpak,
      nixpkgs-unstable,
      nix-index-database,
      sops-nix,
      ...
    }:
    {
      nixosConfigurations.pierre-nixos = nixpkgs.lib.nixosSystem {
        modules = [
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          nix-index-database.nixosModules.default
          ./configuration.nix
        ];
        specialArgs = {
          inherit self;
          userdata = import ./userdata.nix;
          unstable = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
      };
    };
}
