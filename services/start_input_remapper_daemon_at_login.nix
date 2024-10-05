{ config, pkgs, lib, ... }:

let userdata = import ./userdata.nix; in
{
  systemd.services.StartInputRemapperDaemonAtLogin = {
    enable = true;
    description = "Start input-remapper daemon after login";
    serviceConfig = {
        Type = "simple";
    };
    script = lib.getExe(pkgs.writeShellApplication {
        name = "start-input-mapper-daemon";
        runtimeInputs = with pkgs; [input-remapper procps su];
        text = ''
          until pgrep -u ${userdata.username}; do
            sleep 1
          done
          sleep 2
          until [ $(pgrep -c -u root "input-remapper") -gt 1 ]; do
            input-remapper-service&
            sleep 1
            input-remapper-reader-service&
            sleep 1
          done
          su ${userdata.username} -c "input-remapper-control --command stop-all"
          su ${userdata.username} -c "input-remapper-control --command autoload"
          sleep infinity
        '';
    });
    wantedBy = [ "default.target" ];
  };
}
