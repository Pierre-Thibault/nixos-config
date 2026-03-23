{
  ...
}:

{
  services.flatpak = {
    enable = true;
    packages = [
      "net.waterfox.waterfox"
      "nl.hjdskes.gcolor3"
    ];
    overrides = {
      "net.waterfox.waterfox" = {
        Context = {
          filesystems = [
            "home"
            "~/.themes:ro"
            "~/.config/gtk-3.0:ro"
          ];
        };
        Environment = {
          GTK_THEME = "adw-gtk3";
        };
      };
    };
  };
}
