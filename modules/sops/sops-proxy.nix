# sops-nix configuration for API proxy secrets.
# Copy and adjust to match your setup:
#   - defaultSopsFile: path to your encrypted sops file
#   - secrets: one entry per key used in api-proxy.env
#   - templates."api-proxy.env": list only the keys your proxy uses
{ config, self, ... }:
{
  sops = {
    defaultSopsFile = self + "/sops/api-proxy.yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      GROQ_API_KEY = { };
      XAI_API_KEY = { };
      TOGETHER_API_KEY = { };
      OPENAI_API_KEY = { };
      HF_TOKEN = { };
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
