# Wires the OVH signing proxy into the shared api-proxy service. See
# config/ovh-proxy-config.nix for the non-secret config and
# lib/ovh-proxy/ovhsign for what the ovh_sign Caddy module actually does.
{
  pkgs,
  lib,
  ...
}:

let
  cfg = import ../config/ovh-proxy-config.nix;
  customCaddy = import ../lib/ovh-proxy/custom-caddy.nix { inherit pkgs lib; };
in
{
  services.api-proxy = {
    # Superset of stock caddy (adds http.handlers.ovh_sign) -- fine to use
    # for every upstream, not just this one.
    package = customCaddy;

    upstreams.ovh = {
      inherit (cfg) hostname;
      target = "https://${cfg.upstreamHost}";
      # OVH's per-request signature can't be a static header_up -- ovh_sign
      # (below) computes and sets it instead.
      keyEnvVar = null;
      preProxyDirectives = ''
        ovh_sign {
          application_key_env OVH_APPLICATION_KEY
          application_secret_env OVH_APPLICATION_SECRET
          consumer_key_env OVH_CONSUMER_KEY
          upstream_host ${cfg.upstreamHost}
        }
      '';
    };
  };

  environment.sessionVariables = cfg.sessionVars;
}
