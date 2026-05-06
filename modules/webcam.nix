{ pkgs, config, ... }:
{
  environment.systemPackages = [ pkgs.v4l-utils ];

  # v4l2loopback virtual camera device
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="VirtualCam" exclusive_caps=1
  '';

  # Logitech UVC Camera (046d:081b) - disable dynamic framerate on connect
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="video4linux", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="081b", \
      RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/%k --set-ctrl exposure_dynamic_framerate=0"
  '';

  # Pipe real camera to virtual device with stable MJPEG format
  systemd.services.virtual-cam = {
    description = "Virtual camera via v4l2loopback";
    after = [ "dev-video0.device" ];
    bindsTo = [ "dev-video0.device" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.ffmpeg}/bin/ffmpeg -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 30 -i /dev/video0 -vf format=yuv420p -f v4l2 /dev/video10";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
