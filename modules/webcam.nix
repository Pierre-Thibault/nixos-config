{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.v4l-utils ];

  # Logitech UVC Camera (046d:081b) - apply stable capture settings on connect
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="video4linux", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="081b", \
      RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/%k --set-ctrl exposure_dynamic_framerate=0"
  '';
}
