{
  description = "My NixOS's flake";

  nixConfig = {
    extra-substituters = [ "https://cache.nixos-cuda.org" ];
    extra-trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

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

    my-lib.url = "github:Pierre-Thibault/nix-lib";
    my-lib.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      nix-flatpak,
      nixpkgs-unstable,
      nix-index-database,
      sops-nix,
      my-lib,
      ...
    }:
    let
      userdata = import config/userdata.nix;
    in
    {
      nixosConfigurations.${userdata.hostname} = nixpkgs.lib.nixosSystem {
        modules = [
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          nix-index-database.nixosModules.default
          ./configuration.nix
        ];
        specialArgs = {
          inherit self;
          my-lib = my-lib.lib;
          inherit userdata;
          unstable = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
      };
    };
}
