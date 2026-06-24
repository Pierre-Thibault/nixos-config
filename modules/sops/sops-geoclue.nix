# sops-nix configuration for geoclue geo-location.
{ config, self, ... }:
{
  sops = {
    secrets.GOOGLE_API_GEO_KEY = {
      sopsFile = self + "/sops/secrets.yaml";
    };

    templates."geoclue.conf" = {
      content = ''
        [3g]
        enable=true

        [agent]
        whitelist=gnome-shell;io.elementary.desktop.agent-geoclue2

        [cdma]
        enable=true

        [epiphany]
        allowed=true
        system=false
        users=

        [firefox]
        allowed=true
        system=false
        users=

        [get-location]
        allowed=true
        system=true
        users=

        [gnome-color-panel]
        allowed=true
        system=true
        users=

        [gnome-datetime-panel]
        allowed=true
        system=true
        users=

        [modem-gps]
        enable=true

        [network-nmea]
        enable=true

        [org.gnome.Shell]
        allowed=true
        system=true
        users=

        [static-source]
        enable=false

        [wifi]
        enable=true
        submission-nick=geoclue
        submission-url=https://api.beacondb.net/v2/geosubmit
        submit-data=false
        url=https://www.googleapis.com/geolocation/v1/geolocate?key=${config.sops.placeholder.GOOGLE_API_GEO_KEY}

        [xdg-desktop-portal]
        allowed=true
        system=true
        users=
      '';
      group = "geoclue";
      mode = "0440";
    };
  };
}
