{
  ...
}:

{
  services.flatpak = {
    enable = true;
    packages = [
      "io.neovim.nvim"
      "net.waterfox.waterfox"
      "nl.hjdskes.gcolor3"
    ];
  };
}
