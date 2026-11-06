{
  pkgs,
  unstable,
  ...
}:

let
  cfg = import ../../config/ai-config.nix;

  # TODO: remove once nixpkgs-unstable fixes the hash (opencode 2.2.5 isn't
  # on cache.nixos.org because its node_modules fixed-output hash mismatches).
  opencode = unstable.opencode.overrideAttrs (old: {
    node_modules = old.node_modules.overrideAttrs {
      outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
    };
  });
  opencode-desktop = unstable.opencode-desktop.override { inherit opencode; };
in
{
  services.open-webui = {
    enable = true;
    package = unstable.open-webui;
    # Configure providers via the admin panel (Settings → Connections),
    # using http://<hostname>:<port> as base URL and "proxy" as API key.
  };

  users.users.${cfg.username}.packages = with pkgs; [
    aider-chat
    unstable.claude-code
    opencode
    opencode-desktop
  ];
}
