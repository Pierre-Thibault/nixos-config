{
  pkgs,
  ...
}:

let
  userdata = import ../userdata.nix;
in
{
  users.users.${userdata.username}.packages = with pkgs.gnomeExtensions; [
    # The extensions commented are the ones that are only working when installed manually

    # activate-window-by-title  # I'm using my custom version.
    app-icons-taskbar
    appindicator
    blur-my-shell
    caffeine
    cronomix
    #emoji-copy
    hide-cursor
    nasa-apod
    native-window-placement
    night-light-slider-updated
    night-theme-switcher
    #open-bar
    pano
    removable-drive-menu
    rounded-corners
    run-or-raise
    space-bar
    tiling-shell
    #tilingnome
    top-bar-organizer
    user-themes
    vitals
    windownavigator
  ];

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-shell-extensions # Remove default extensions
  ];
}
