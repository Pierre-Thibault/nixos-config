{
  config,
  pkgs,
  lib,
  ...
}:

let
  userdata = import ./userdata.nix;
in
{
  users.users.${userdata.username}.packages = with pkgs; [
    brave
    nemo-with-extensions
    clipgrab
    deja-dup
    discord
    gedit
    gimp
    gittyup
    gnome-browser-connector
    gnome-screenshot
    gnome-terminal
    gnome-tweaks
    google-chrome
    guake
    jetbrains.rust-rover
    keepass
    keepassxc
    keymapp
    libreoffice
    lm_sensors
    menulibre
    obs-studio
    obsidian
    ocrfeeder
    openvpn
    protonvpn-gui
    qalculate-gtk
    tesseract
    vlc
    vscodium
  ];
}
