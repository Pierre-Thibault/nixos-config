{
  description = "My NixOS's flake";

  nixConfig = {
    extra-substituters = [ "https://cuda-maintainers.cachix.org" ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E"
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
      hostname = (import config/userdata.nix).hostname;
    in
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        modules = [
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          nix-index-database.nixosModules.default
          ./configuration.nix
        ];
        specialArgs = {
          inherit self;
          my-lib = my-lib.lib;
          userdata = import config/userdata.nix;
          unstable = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
      };
    };
}
