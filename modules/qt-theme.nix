{ pkgs, ... }:

{
  # Configure Qt to use Adwaita theme matching GTK
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita";
  };

  # Install required Qt theme packages
  environment.systemPackages = with pkgs; [
    adwaita-qt
    adwaita-qt6
    qgnomeplatform
    qgnomeplatform-qt6
    libsForQt5.qtstyleplugins
  ];

  # Force Qt apps to follow GTK theme and colors
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "gnome";
    QT_STYLE_OVERRIDE = "adwaita";
  };
}
