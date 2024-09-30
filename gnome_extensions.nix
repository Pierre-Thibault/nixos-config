{ config, pkgs, lib, ... }:

{
  users.users.pierre.packages = with pkgs.gnomeExtensions; [
    blur-my-shell
    caffeine
    clipboard-history
    custom-hot-corners-extended
    dash-to-panel
    #emoji-copy
    nasa-apod
    native-window-placement
    night-light-slider-updated
    night-theme-switcher
    #pano
    rounded-corners
    #tilingnome
    transparent-window-moving
    vitals
    weather-oclock
  ];

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };
}
