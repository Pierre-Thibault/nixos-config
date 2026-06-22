{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    adw-gtk3
    age
    corefonts
    gparted
    input-remapper
    jq
    pinentry-curses
    sops
    ssh-to-age
    v4l-utils
    xwayland-satellite
  ];
}
