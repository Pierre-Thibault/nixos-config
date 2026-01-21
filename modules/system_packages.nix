{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    corefonts
    ecryptfs
    gnomeExtensions.gsconnect
    gparted
    input-remapper
    jq
    pinentry-curses
  ];
}
