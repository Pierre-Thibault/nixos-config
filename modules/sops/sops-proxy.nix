# sops-nix configuration for API proxy secrets.
# Copy and adjust to match your setup:
#   - defaultSopsFile: path to your encrypted sops file
#   - secrets: one entry per key used in api-proxy.env
#   - templates."api-proxy.env": list only the keys your proxy uses
{ config, self, lib, userdata, ... }:
let
  ovhSopsFile = self + "/sops/ovh.yaml";
in
{
  sops = {
    defaultSopsFile = self + "/sops/api-proxy.yaml";
    # Self-generated, independent of sshd (services.openssh.enable = false
    # on this host, so /etc/ssh/ssh_host_ed25519_key never exists).
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;

    # Gated by userdata.enableSops (set false only during the sops
    # bootstrap dance, see doc/disaster-recovery.md): unlike
    # defaultSopsFile/age.* above, these two require an age identity
    # already listed in .sops.yaml, which a freshly bootstrapped
    # machine doesn't have yet.
    secrets = lib.optionalAttrs userdata.enableSops {
      GROQ_API_KEY = { };
      XAI_API_KEY = { };
      TOGETHER_API_KEY = { };
      OPENAI_API_KEY = { };
      HF_TOKEN = { };
      OPEN_ROUTER = { };
      DIGITALOCEAN_TOKEN = { sopsFile = self + "/sops/digital-ocean.yaml"; };
      # The Nix-side name (env var this ends up as) is uppercase to match
      # the other secrets here, but the actual key in sops/ovh.yaml is
      # lowercase (ovh_application_key etc.) -- key remaps to it.
      OVH_APPLICATION_KEY = {
        sopsFile = ovhSopsFile;
        key = "ovh_application_key";
      };
      OVH_APPLICATION_SECRET = {
        sopsFile = ovhSopsFile;
        key = "ovh_application_secret";
      };
      OVH_CONSUMER_KEY = {
        sopsFile = ovhSopsFile;
        key = "ovh_consumer_key";
      };
    };

    templates = lib.optionalAttrs userdata.enableSops {
      "api-proxy.env" = {
        content = ''
          GROQ_API_KEY=${config.sops.placeholder.GROQ_API_KEY}
          XAI_API_KEY=${config.sops.placeholder.XAI_API_KEY}
          TOGETHER_API_KEY=${config.sops.placeholder.TOGETHER_API_KEY}
          OPENAI_API_KEY=${config.sops.placeholder.OPENAI_API_KEY}
          HF_TOKEN=${config.sops.placeholder.HF_TOKEN}
          OPEN_ROUTER=${config.sops.placeholder.OPEN_ROUTER}
          DIGITALOCEAN_TOKEN=${config.sops.placeholder.DIGITALOCEAN_TOKEN}
          OVH_APPLICATION_KEY=${config.sops.placeholder.OVH_APPLICATION_KEY}
          OVH_APPLICATION_SECRET=${config.sops.placeholder.OVH_APPLICATION_SECRET}
          OVH_CONSUMER_KEY=${config.sops.placeholder.OVH_CONSUMER_KEY}
        '';
        # The "caddy" group only exists while userdata.enableCaddyProxy
        # creates the caddy service; matching it here to that same flag
        # keeps both dependents in sync instead of two separate switches.
        mode = "0440";
      }
      // lib.optionalAttrs userdata.enableCaddyProxy {
        group = "caddy";
        # EnvironmentFile is only read by systemd when the unit starts, not
        # on the Caddyfile-triggered reload in api-proxy.nix — without this,
        # a new or rotated key silently never reaches the running process.
        restartUnits = [ "caddy.service" ];
      };
    };
  };
}
