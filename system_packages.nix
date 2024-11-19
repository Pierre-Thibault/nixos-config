{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
      corefonts
      ecryptfs
      gparted
      gnomeExtensions.gsconnect
      input-remapper
      pinentry-curses
  ];
}
