{ config, pkgs, lib, ... }:

{
  systemd.services.RestoreAlsaVolume = {
      enable = true;
      description = "Setting SPDIF ALSA volume at 100% after sleep.";
      after = [ "suspend.target" ];
      serviceConfig = {
        User = "pierre";
      	Type = "forking";
      };
      script = lib.getExe(pkgs.writeShellApplication {
          name = "reload-input-mapper-config";
          runtimeInputs = with pkgs; [alsa-utils];
          text = ''
	          amixer -c "PRMA" set PCM,0 100%
            amixer -c "PRMA" set PCM,1 100%
         '';
       });
       wantedBy = [ "suspend.target" ];
  };
}