# Wires cloud-proxy-config.nix's providers into the shared api-proxy service
# (enable/port/environmentFile are set once in modules/ai/ai.nix).
{ lib, self, ... }:

let
  cfg = import ../../config/cloud-proxy-config.nix;

  toUpstream =
    _name: provider:
    {
      inherit (provider) hostname target keyEnvVar;
    }
    // lib.optionalAttrs (provider ? keyHeader) { inherit (provider) keyHeader; }
    // lib.optionalAttrs (provider ? keyScheme) { inherit (provider) keyScheme; }
    // lib.optionalAttrs (provider ? useTls) { inherit (provider) useTls; };

  sessionVars = lib.foldlAttrs (
    acc: _name: provider:
    acc // (provider.sessionVars or { })
  ) { } cfg.providers;
in
{
  services.api-proxy.upstreams = lib.mapAttrs toUpstream cfg.providers;
  services.api-proxy.tlsTrustFile = self + "/certs/caddy-local-ca.crt";

  environment.sessionVariables = sessionVars;
}
