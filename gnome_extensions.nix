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
  users.users.${userdata.username}.packages = with pkgs.gnomeExtensions; [
    activate-window-by-title
    app-icons-taskbar
    blur-my-shell
    caffeine
    clipboard-history
    custom-hot-corners-extended
    hide-cursor
    #emoji-copy
    native-window-placement
    night-light-slider-updated
    night-theme-switcher
    #open-bar
    pano
    rounded-corners
    run-or-raise
    space-bar
    #tilingnome
    #top-bar-organizer
    vitals
  ];

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };
}
