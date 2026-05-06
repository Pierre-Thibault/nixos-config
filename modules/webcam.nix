{ pkgs, config, ... }:
{
  environment.systemPackages = [ pkgs.v4l-utils ];

  # v4l2loopback virtual camera device (available if needed)
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="VirtualCam" exclusive_caps=1
  '';

  # Logitech UVC Camera (046d:081b) - disable dynamic framerate to fix flickering
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="video4linux", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="081b", \
      RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/%k --set-ctrl exposure_dynamic_framerate=0"
  '';
}
