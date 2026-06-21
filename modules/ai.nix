{
  pkgs,
  unstable,
  ...
}:

let
  userdata = import ../userdata.nix;
in
{
  services.open-webui = {
    enable = true;
    package = unstable.open-webui;
    # Configure providers via the admin panel (Settings → Connections),
    # using http://127.0.0.1:<port> as base URL and "proxy" as API key.
  };

  services.api-proxy = {
    enable = true;
    port = 4140;
    environmentFile = "/home/${userdata.username}/secrets/api-proxy.env";
    secretsDirectoryOwner = userdata.username;
    upstreams = {
      # Uncomment if you have an Anthropic API key.
      # Note: incompatible with Claude Code subscription auth — choose one.
      # anthropic = {
      #   hostname = "anthropic.proxy";
      #   target = "https://api.anthropic.com";
      #   keyHeader = "x-api-key";
      #   keyScheme = "";
      #   keyEnvVar = "ANTHROPIC_API_KEY";
      # };
      groq = {
        hostname = "groq.proxy";
        target = "https://api.groq.com";
        keyEnvVar = "GROQ_API_KEY";
      };
      xai = {
        hostname = "xai.proxy";
        target = "https://api.x.ai";
        keyEnvVar = "XAI_API_KEY";
      };
      together = {
        hostname = "togetherai.proxy";
        target = "https://api.together.xyz";
        keyEnvVar = "TOGETHER_API_KEY";
      };
      openai = {
        hostname = "openai.proxy";
        target = "https://api.openai.com";
        keyEnvVar = "OPENAI_API_KEY";
      };
      huggingface = {
        hostname = "huggingface.proxy";
        target = "https://huggingface.co";
        keyEnvVar = "HF_TOKEN";
      };
    };
  };

  # Dummy keys for session tools (Claude Code, Aider).
  # Real keys never leave the proxy service.
  environment.sessionVariables = {
    # Uncomment if you have an Anthropic API key.
    # Note: incompatible with Claude Code subscription auth — choose one.
    # ANTHROPIC_BASE_URL = "http://anthropic.proxy:4140";
    # ANTHROPIC_API_KEY = "proxy";
    OPENAI_BASE_URL = "http://openai.proxy:4140/v1";
    OPENAI_API_KEY = "proxy";
    GROQ_API_BASE = "http://groq.proxy:4140";
    GROQ_API_KEY = "proxy";
    XAI_API_BASE = "http://xai.proxy:4140";
    XAI_API_KEY = "proxy";
    TOGETHERAI_API_BASE = "http://togetherai.proxy:4140";
    TOGETHERAI_API_KEY = "proxy";
    HF_ENDPOINT = "http://huggingface.proxy:4140";
    HF_TOKEN = "proxy";
  };

  users.users.${userdata.username}.packages = with pkgs; [
    aider-chat
  ];
}
