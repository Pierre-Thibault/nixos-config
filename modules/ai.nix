{
  pkgs,
  ...
}:

let
  userdata = import ../userdata.nix;
in
{
  services.open-webui.enable = true;
  users.users.${userdata.username}.packages = with pkgs; [
    aider-chat
  ];
}
