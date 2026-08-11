{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.api-proxy;

  bindAddr = cfg.bindAddr;
  port = toString cfg.port;
  httpsPort = toString cfg.httpsPort;
  inherit (lib) mkForce mkOption types;

  upstreamBlock =
    _name: upstream:
    let
      scheme = if upstream.useTls then "https" else "http";
      # Caddy cannot multiplex HTTP and HTTPS on the same listening port, so
      # TLS upstreams get their own dedicated port.
      upstreamPort = if upstream.useTls then httpsPort else port;
      # Most upstreams authenticate with one static header (a bearer token,
      # say) that Caddy can inject by itself. Some (OVH) need a signature
      # computed per request instead -- those set preProxyDirectives (e.g.
      # `ovh_sign { ... }`, see modules/ovh-proxy) and leave keyEnvVar null.
      headerUpLine = lib.optionalString (upstream.keyEnvVar != null) ''
        header_up ${upstream.keyHeader} "${upstream.keyScheme}{env.${upstream.keyEnvVar}}"
      '';
    in
    ''
      ${scheme}://${upstream.hostname}:${upstreamPort} {
        bind ${bindAddr}
        ${lib.optionalString upstream.useTls "tls internal"}
        log {
          output stdout
        }
        # route wraps everything below so custom directives like ovh_sign
        # (which Caddy has no implicit ordering for) run in the order
        # written, right before reverse_proxy -- without it Caddy refuses
        # to adapt the Caddyfile at all for any non-standard directive.
        route {
          ${upstream.preProxyDirectives}
          reverse_proxy ${upstream.target} {
            ${headerUpLine}
          }
        }
      }
    '';

  caddyfile = pkgs.writeText "api-proxy-caddyfile" (
    lib.concatStringsSep "\n" (lib.mapAttrsToList upstreamBlock cfg.upstreams)
  );

  upstreamSubmodule = types.submodule {
    options = {
      hostname = mkOption {
        type = types.str;
        description = "Local hostname for this upstream (e.g. groq.proxy). Must resolve to 127.0.0.1 via networking.hosts.";
      };
      target = mkOption {
        type = types.str;
        description = "Upstream API base URL (e.g. https://api.anthropic.com).";
      };
      keyHeader = mkOption {
        type = types.str;
        default = "Authorization";
        description = "Header used to authenticate with the upstream.";
      };
      keyScheme = mkOption {
        type = types.str;
        default = "Bearer ";
        description = "Prefix before the API key value (e.g. \"Bearer \" or \"\").";
      };
      keyEnvVar = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Name of the environment variable holding the real API key, injected via a static header_up. Leave null when preProxyDirectives handles auth instead (e.g. ovh_sign, whose signature can't be a single static header).";
      };
      useTls = mkOption {
        type = types.bool;
        default = false;
        description = "Serve this upstream over HTTPS using Caddy's internal CA instead of plain HTTP. Needed for clients that require an https:// scheme (e.g. `pulumi login`).";
      };
      preProxyDirectives = mkOption {
        type = types.lines;
        default = "";
        description = "Raw Caddyfile directives inserted before reverse_proxy, for upstreams whose auth can't be expressed as a single static header_up (e.g. `ovh_sign { ... }` for OVH's per-request signature). Requires a Caddy package with the matching module -- see the `package` option.";
      };
    };
  };
in
{
  options.services.api-proxy = {
    enable = lib.mkEnableOption "Caddy-based API key proxy";

    bindAddr = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to bind to. Defaults to localhost only.";
    };

    port = mkOption {
      type = types.port;
      default = 4140;
      description = "Local port shared by all plain-HTTP upstream proxies, differentiated by hostname.";
    };

    httpsPort = mkOption {
      type = types.port;
      default = 4141;
      description = "Local port shared by all HTTPS (useTls) upstream proxies, differentiated by hostname. Separate from `port` because Caddy cannot multiplex HTTP and HTTPS on the same listening port.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.caddy;
      description = "Caddy package to run. Override to a custom build (see modules/ovh-proxy/custom-caddy.nix) if any upstream's preProxyDirectives needs a module beyond stock Caddy.";
    };

    environmentFile = mkOption {
      type = types.str;
      description = "Path to a KEY=value file containing the real API keys. Must be readable by the caddy group.";
      example = "/home/user/secrets/api-proxy.env";
    };

    secretsDirectoryOwner = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "If set, ensures the parent directory of environmentFile has permissions 750 <owner>:caddy so the Caddy service can traverse it.";
    };

    tlsTrustFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to Caddy's internal CA root certificate (PEM), added to the
        system trust store so HTTPS clients (e.g. `pulumi login`) accept
        `useTls` upstreams without an insecure/skip-verify flag. Caddy
        generates this certificate itself on first run at
        /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt —
        copy it into the repo once and point this option at that copy.
        Only needed if at least one upstream sets useTls = true.
      '';
    };

    upstreams = mkOption {
      type = types.attrsOf upstreamSubmodule;
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
      package = cfg.package;
    };

    systemd = {
      services.caddy = {
        serviceConfig.EnvironmentFile = cfg.environmentFile;
        reloadTriggers = mkForce [ caddyfile ];
        restartTriggers = mkForce [ ];
      };
      tmpfiles.rules = lib.optionals (cfg.secretsDirectoryOwner != null) [
        "d ${dirOf cfg.environmentFile} 750 ${cfg.secretsDirectoryOwner} caddy -"
      ];
    };

    networking.hosts.${bindAddr} = lib.mapAttrsToList (
      _name: upstream: upstream.hostname
    ) cfg.upstreams;

    security.pki.certificateFiles = lib.optional (cfg.tlsTrustFile != null) cfg.tlsTrustFile;
  };
}
