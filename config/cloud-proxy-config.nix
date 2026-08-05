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

    # HTTPS required: `pulumi login` refuses plain http:// for a self-hosted
    # backend URL. Caddy serves this one over its internal CA (tls internal);
    # `pulumi login` needs --insecure to accept the unverified cert.
    pulumi = {
      hostname = "pulumi.proxy";
      target = "https://api.pulumi.com";
      keyHeader = "Authorization";
      keyScheme = "token ";
      keyEnvVar = "PULUMI_ACCESS_TOKEN";
      useTls = true;
    };
  };
}
