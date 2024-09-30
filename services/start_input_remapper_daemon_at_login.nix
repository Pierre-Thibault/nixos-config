{ config, pkgs, lib, ... }:

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
          until pgrep -u pierre; do
            sleep 1
          done
          sleep 2
          until [ $(pgrep -c -u root "input-remapper") -gt 1 ]; do
            input-remapper-service&
            sleep 1
            input-remapper-reader-service&
            sleep 1
          done
          su pierre -c "input-remapper-control --command stop-all"
          su pierre -c "input-remapper-control --command autoload"
          sleep infinity
        '';
    });
    wantedBy = [ "default.target" ];
  };
}
