{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.api-proxy;

  upstreamBlock = _name: upstream:
    let
      envRef = "{$" + upstream.keyEnvVar + "}";
    in ''
      http://${upstream.hostname}:${toString cfg.port} {
        bind 127.0.0.1
        reverse_proxy ${upstream.target} {
          header_up -x-api-key
          header_up ${upstream.keyHeader} "${upstream.keyScheme}${envRef}"
        }
      }
    '';

  caddyfile = pkgs.writeText "api-proxy-caddyfile" (''
    {
      # The admin API is disabled to prevent real API keys from being readable
      # at http://localhost:2019/config/ — Caddy embeds substituted key values
      # in its compiled JSON config, which the admin API exposes in plaintext.
      # Trade-off: `systemctl reload caddy` no longer works gracefully; NixOS
      # automatically falls back to `systemctl restart caddy` on reload failure,
      # causing a brief interruption when the proxy config changes.
      admin off
    }

  '' + lib.concatStringsSep "\n" (lib.mapAttrsToList upstreamBlock cfg.upstreams));

  upstreamSubmodule = lib.types.submodule {
    options = {
      hostname = lib.mkOption {
        type = lib.types.str;
        description = "Local hostname for this upstream (e.g. groq.proxy). Must resolve to 127.0.0.1 via networking.hosts.";
      };
      target = lib.mkOption {
        type = lib.types.str;
        description = "Upstream API base URL (e.g. https://api.anthropic.com).";
      };
      keyHeader = lib.mkOption {
        type = lib.types.str;
        default = "Authorization";
        description = "Header used to authenticate with the upstream.";
      };
      keyScheme = lib.mkOption {
        type = lib.types.str;
        default = "Bearer ";
        description = "Prefix before the API key value (e.g. \"Bearer \" or \"\").";
      };
      keyEnvVar = lib.mkOption {
        type = lib.types.str;
        description = "Name of the environment variable holding the real API key.";
      };
    };
  };
in
{
  options.services.api-proxy = {
    enable = lib.mkEnableOption "Caddy-based API key proxy";

    port = lib.mkOption {
      type = lib.types.port;
      default = 4140;
      description = "Single local port shared by all upstream proxies, differentiated by hostname.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to a KEY=value file containing the real API keys. Must be readable by the caddy group.";
      example = "/home/user/secrets/api-proxy.env";
    };

    secretsDirectoryOwner = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "If set, ensures the parent directory of environmentFile has permissions 750 <owner>:caddy so the Caddy service can traverse it.";
    };

    upstreams = lib.mkOption {
      type = lib.types.attrsOf upstreamSubmodule;
      default = { };
      description = "API providers to proxy, keyed by an arbitrary name.";
      example = {
        anthropic = {
          hostname = "anthropic.proxy";
          target = "https://api.anthropic.com";
          keyHeader = "x-api-key";
          keyScheme = "";
          keyEnvVar = "ANTHROPIC_API_KEY";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      configFile = caddyfile;
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile = cfg.environmentFile;

    networking.hosts."127.0.0.1" =
      lib.mapAttrsToList (_name: upstream: upstream.hostname) cfg.upstreams;

    systemd.tmpfiles.rules = lib.optionals (cfg.secretsDirectoryOwner != null) [
      "d ${dirOf cfg.environmentFile} 750 ${cfg.secretsDirectoryOwner} caddy -"
    ];
  };
}
