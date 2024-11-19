{ config, pkgs, lib, ... }:

let userdata = import ./userdata.nix; in
{
  users.users.${userdata.username}.packages = with pkgs; [
      brave
      cinnamon.nemo-with-extensions
      clipgrab
      deja-dup
      discord
      gedit
      gimp
      gnome-browser-connector
      gnome.gnome-screenshot
      gnome.gnome-terminal
      gnome.gnome-tweaks
      google-chrome
      guake
      helix
      jetbrains.rust-rover
      keepass
      keepassxc
      keymapp
      libreoffice
      lm_sensors
      mc
      menulibre
      obs-studio
      obsidian
      ocrfeeder
      openvpn
      protonvpn-gui
      psensor
      qalculate-gtk
      tesseract
      vlc
      vscodium
  ];
}
