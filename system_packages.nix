{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
      ecryptfs
      gparted
      gnomeExtensions.gsconnect
      input-remapper
  ];
}