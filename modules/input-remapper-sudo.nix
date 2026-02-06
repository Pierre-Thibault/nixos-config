{ config, pkgs, lib, ... }:

let userdata = import ../userdata.nix; in
{
  # Enable input-remapper service
  services.input-remapper.enable = true;

  # Allow user to restart input-remapper daemon without password
  security.sudo.extraRules = [
    {
      users = [ userdata.username ];
      commands = [
        {
          command = "/run/current-system/sw/bin/pkill";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/input-remapper-service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/input-remapper-reader-service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
