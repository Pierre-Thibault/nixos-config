# configurationLimit in systemd-boot only trims the boot menu entries,
# it does not delete the underlying system profile generations, so the
# nix store keeps growing forever unless something else prunes them.
{ pkgs, ... }:

{
  nix.settings = {
    # Auto-collect garbage during builds/substitutions instead of waiting
    # for the weekly timer, so the store never fills up completely again.
    min-free = 5000000000; # 5 GB
    max-free = 10000000000; # 10 GB
  };

  systemd.services.nix-gc-generations = {
    description = "Keep only the last 50 NixOS generations and collect garbage";
    script = ''
      ${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +50
      ${pkgs.nix}/bin/nix-collect-garbage
      ${pkgs.nix}/bin/nix-store --optimise
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.nix-gc-generations = {
    description = "Weekly NixOS generation cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
