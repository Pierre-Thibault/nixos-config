# Non-AI cloud/infra providers proxied through the same Caddy API-key proxy
# defined by ai-config.nix (shared port and secretsFile — see modules/ai/ai.nix
# for enable/port/environmentFile wiring). This file only contributes upstreams.
let
  port = 4140;
  portStr = toString port;
in
{
  providers = {
    digitalocean = {
      hostname = "digitalocean.proxy";
      target = "https://api.digitalocean.com";
      keyEnvVar = "DIGITALOCEAN_TOKEN";
      sessionVars = {
        DIGITALOCEAN_API_URL = "http://digitalocean.proxy:${portStr}";
      };
    };
  };
}
