# sops-nix configuration for API proxy secrets.
# Copy and adjust to match your setup:
#   - defaultSopsFile: path to your encrypted sops file
#   - secrets: one entry per key used in api-proxy.env
#   - templates."api-proxy.env": list only the keys your proxy uses
{ config, self, lib, userdata, ... }:
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
