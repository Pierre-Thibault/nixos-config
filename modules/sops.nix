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
