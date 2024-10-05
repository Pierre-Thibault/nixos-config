{ config, pkgs, lib, ... }:

let userdata = import ./userdata.nix; in
{
  systemd.services.ReloadInputRemapperAfterSleep = {
      enable = true;
      description = "Reload input-remapper config after sleep";
      after = [ "suspend.target" ];
      serviceConfig = {
        User = userdata.username;
	      Type = "forking";
      };
      script = lib.getExe(pkgs.writeShellApplication {
          name = "reload-input-mapper-config";
          runtimeInputs = with pkgs; [input-remapper ps gawk];
          text = ''
              input-remapper-control --command stop-all
              input-remapper-control --command autoload
              sleep 1
              until [[ $(ps aux | awk '$11~"input-remapper" && $12="<defunct>" {print $0}' | wc -l) -eq 0 ]]; do
                input-remapper-control --command stop-all
                input-remapper-control --command autoload
                sleep 1
              done
         '';
       });
       wantedBy = [ "suspend.target" ];
  };
}
