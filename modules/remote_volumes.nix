{ pkgs, userdata, ... }:

let
  icloudDir = "/home/${userdata.username}/icloud";
  protonDir = "/home/${userdata.username}/proton";
in
{
  programs.fuse.userAllowOther = true;

  systemd.tmpfiles.rules = [
    "d ${icloudDir} 0755 ${userdata.username} users - -"
    "d ${protonDir} 0755 ${userdata.username} users - -"
  ];

  systemd.user.services.rclone-icloud = {
    description = "iCloud Drive (rclone)";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = [ "/run/wrappers" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rclone}/bin/rclone mount icloud: ${icloudDir} --vfs-cache-mode writes";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  systemd.user.services.rclone-proton = {
    description = "Proton Drive (rclone)";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = [ "/run/wrappers" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rclone}/bin/rclone mount proton: ${protonDir} --vfs-cache-mode writes";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
