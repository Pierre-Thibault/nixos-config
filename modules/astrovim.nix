{
  pkgs,
  ...
}:

let
  userdata = import ../userdata.nix;
in
{
  users.users.${userdata.username}.packages = with pkgs; [
    bottom
    lazygit
    neovim
    nodejs_23
    ripgrep
    tree-sitter
    wl-clipboard
  ];
}
