{
  ...
}:

# Somehow, I am not able to list my flatpak in an external module
{
  services.flatpak = {
    enable = true;
    packages = [
      "net.waterfox.waterfox"
    ];
  };
}
