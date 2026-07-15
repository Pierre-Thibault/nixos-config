{
  lib,
  ...
}:

let
  cfg = import ../../config/ai-config.nix;

  # Strip sessionVars before passing to api-proxy.
  toUpstream =
    _name: provider:
    {
      inherit (provider) hostname target keyEnvVar;
    }
    // lib.optionalAttrs (provider ? keyHeader) { inherit (provider) keyHeader; }
    // lib.optionalAttrs (provider ? keyScheme) { inherit (provider) keyScheme; };

  # Merge all provider sessionVars into a single attrset.
  sessionVars = lib.foldlAttrs (
    acc: _name: provider:
    acc // (provider.sessionVars or { })
  ) { } cfg.providers;
in
{
  services.api-proxy = {
    enable = true;
    port = cfg.port;
    environmentFile = cfg.secretsFile;
    upstreams = lib.mapAttrs toUpstream cfg.providers;
  };

  # Dummy keys pointing to the local proxy.
  # Real keys never leave the proxy service.
  environment.sessionVariables = sessionVars;

}
