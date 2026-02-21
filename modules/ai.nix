{
  pkgs,
  unstable,
  ...
}:

let
  userdata = import ../userdata.nix;
in
{
  services.open-webui = {
    enable = true;
    package = unstable.open-webui;
  };
  users.users.${userdata.username}.packages = with pkgs; [
    aider-chat
  ];
}
