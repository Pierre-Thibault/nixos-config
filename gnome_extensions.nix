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
    # The extensions commented are the ones that are only working when installed manually

    activate-window-by-title
    app-icons-taskbar
    blur-my-shell
    caffeine
    clipboard-history
    cronomix
    custom-hot-corners-extended
    #emoji-copy
    hide-cursor
    nasa-apod
    native-window-placement
    night-light-slider-updated
    night-theme-switcher
    #open-bar
    pano
    rounded-corners
    run-or-raise
    space-bar
    tiling-shell
    #tilingnome
    #top-bar-organizer
    top-panel-note
    vitals
  ];

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  environment.gnome.excludePackages = with pkgs.gnomeExtensions; [
    applications-menu
    clipboard-history
    custom-hot-corners-extended
    launch-new-instance
    light-style
    places-status-indicator
    screenshot-window-sizer
    smart-auto-move
    status-icons
    system-monitor
    window-list
    workspace-indicator
  ];
}
