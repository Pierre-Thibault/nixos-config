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
  ];
}
