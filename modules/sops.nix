{ config, ... }:
{
  sops = {
    defaultSopsFile = ../sops/api-proxy.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      GROQ_API_KEY = { };
      XAI_API_KEY = { };
      TOGETHER_API_KEY = { };
      OPENAI_API_KEY = { };
      HF_TOKEN = { };
      GOOGLE_API_GEO_KEY = { };
      ICLOUD_PASSWORD = {
        owner = "pierre";
        path = "/run/secrets/icloud-password";
      };
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

    templates."api-proxy.env" = {
      content = ''
        GROQ_API_KEY=${config.sops.placeholder.GROQ_API_KEY}
        XAI_API_KEY=${config.sops.placeholder.XAI_API_KEY}
        TOGETHER_API_KEY=${config.sops.placeholder.TOGETHER_API_KEY}
        OPENAI_API_KEY=${config.sops.placeholder.OPENAI_API_KEY}
        HF_TOKEN=${config.sops.placeholder.HF_TOKEN}
      '';
      group = "caddy";
      mode = "0440";
    };
  };
}
