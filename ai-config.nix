# User-specific AI tools configuration.
# Copy and adjust this file to match your own setup.
# ai.nix and api-proxy.nix are generic and do not need to be modified.
let
  userdata = import ./userdata.nix;
  port = 4140;
  portStr = toString port;
in
{
  inherit (userdata) username;

  # Path to a KEY=VALUE file containing real API keys.
  # Must be readable by the caddy group (e.g. permissions: root:caddy 440).
  secretsFile = "/run/secrets/rendered/api-proxy.env";

  # Local port shared by all providers, differentiated by hostname.
  inherit port;

  # API providers to proxy. Each entry requires:
  #   hostname    — local virtual hostname resolving to 127.0.0.1
  #   target      — real upstream API base URL
  #   keyEnvVar   — variable name holding the real key in secretsFile
  #   keyHeader   — (optional) authentication header, defaults to "Authorization"
  #   keyScheme   — (optional) key prefix, defaults to "Bearer "
  #   sessionVars — environment variables exposed to CLI tools (Aider, etc.)
  #                 pointing to the local proxy with a dummy key value
  providers = {
    # Uncomment to add Anthropic support.
    # Note: incompatible with Claude Code subscription auth — choose one.
    # anthropic = {
    #   hostname = "anthropic.proxy";
    #   target = "https://api.anthropic.com";
    #   keyHeader = "x-api-key";
    #   keyScheme = "";
    #   keyEnvVar = "ANTHROPIC_API_KEY";
    #   sessionVars = {
    #     ANTHROPIC_BASE_URL = "http://anthropic.proxy:${portStr}";
    #     ANTHROPIC_API_KEY = "proxy";
    #   };
    # };

    groq = {
      hostname = "groq.proxy";
      target = "https://api.groq.com";
      keyEnvVar = "GROQ_API_KEY";
      sessionVars = {
        GROQ_API_BASE = "http://groq.proxy:${portStr}";
        GROQ_API_KEY = "proxy";
      };
    };

    xai = {
      hostname = "xai.proxy";
      target = "https://api.x.ai";
      keyEnvVar = "XAI_API_KEY";
      sessionVars = {
        XAI_API_BASE = "http://xai.proxy:${portStr}";
        XAI_API_KEY = "proxy";
      };
    };

    together = {
      hostname = "togetherai.proxy";
      target = "https://api.together.xyz";
      keyEnvVar = "TOGETHER_API_KEY";
      sessionVars = {
        TOGETHERAI_API_BASE = "http://togetherai.proxy:${portStr}";
        TOGETHERAI_API_KEY = "proxy";
      };
    };

    openai = {
      hostname = "openai.proxy";
      target = "https://api.openai.com";
      keyEnvVar = "OPENAI_API_KEY";
      sessionVars = {
        OPENAI_BASE_URL = "http://openai.proxy:${portStr}/v1";
        OPENAI_API_KEY = "proxy";
      };
    };

    huggingface = {
      hostname = "huggingface.proxy";
      target = "https://huggingface.co";
      keyEnvVar = "HF_TOKEN";
      sessionVars = {
        HF_ENDPOINT = "http://huggingface.proxy:${portStr}";
        HF_TOKEN = "proxy";
      };
    };
  };
}
