{
  pkgs,
  unstable,
  ...
}:

let
  cfg = import ../../config/ai-config.nix;

  opencode = unstable.opencode;
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
    unstable.herdr
    unstable.herdr-core
    unstable.herdr-desktop
    unstable.claude-code
    opencode
    opencode-desktop
  ];
}
