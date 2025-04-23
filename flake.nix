# This is not a file using the Nix language so I can not define variables
# pierre-nixos must be changed manually.
{
  description = "My NixOS's flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };
  outputs =
    {
      nixpkgs,
      nix-flatpak,
      ...
    }:
    let
      unstableTarball = fetchTarball {
        url = "https://releases.nixos.org/nixos/unstable/nixos-25.05pre787278.c11863f1e964/nixexprs.tar.xz";
        sha256 = "0a16swsbgnzr5j991ggq17fiyyfvcn434k624250b4rp9bdj83hx";
      };
      unstable = import unstableTarball { system = "x86_64-linux"; };
    in
    {
      nixosConfigurations.pierre-nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit unstable;
        };
        modules = [
          nix-flatpak.nixosModules.nix-flatpak
          ./configuration.nix
        ];
      };
    };
}
