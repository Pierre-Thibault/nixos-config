{
  pkgs,
  ...
}:

let
  userdata = import ../userdata.nix;
in
{
  users.users.${userdata.username}.packages = with pkgs.python313Packages; [
    weasyprint
  ];
}
