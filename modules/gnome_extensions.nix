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

    activate-window-by-title
    appindicator
    blur-my-shell
    caffeine
    color-picker
    emoji-copy
    hide-cursor
    night-light-slider-updated
    night-theme-switcher
    open-bar
    pano
    removable-drive-menu
    rounded-corners
    run-or-raise
    space-bar
    tiling-shell
    windownavigator
  ];

  # programs.kdeconnect = {
  #   enable = true;
  #   package = pkgs.gnomeExtensions.gsconnect;
  # };

  environment.gnome.excludePackages = with pkgs; [
    gnome-shell-extensions # Remove default extensions
  ];
}
