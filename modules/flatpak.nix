{
  ...
}:

{
  services.flatpak = {
    enable = true;
    packages = [
      "net.waterfox.waterfox"
      "nl.hjdskes.gcolor3"
      "org.gnome.Calendar"
    ];
  };
}
