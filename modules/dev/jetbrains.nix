{
  pkgs,
  userdata,
  ...
}:
{
  users.users.${userdata.username}.packages = with pkgs.jetbrains; [
    pycharm
    rust-rover
  ];
}
