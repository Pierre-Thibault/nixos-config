{
  pkgs,
  ...
}:

let
  userdata = import ../userdata.nix;
in
{
  users.users.${userdata.username}.packages = with pkgs.jetbrains; [
    pycharm-community-src
    pycharm-professional
    rust-rover
    webstorm
  ];
}
