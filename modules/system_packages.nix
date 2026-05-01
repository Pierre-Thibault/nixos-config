{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    adw-gtk3
    corefonts
    ecryptfs
    gnomeExtensions.gsconnect
    gparted
    input-remapper
    jq
    pinentry-curses
    v4l-utils
    xwayland-satellite
  ];
}
