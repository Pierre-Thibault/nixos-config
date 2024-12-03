{
  config,
  pkgs,
  lib,
  ...
}:

let
  userdata = import ./userdata.nix;
in
{
  users.users.${userdata.username}.packages = with pkgs; [
    direnv
    fanctl
    file
    gcc
    git
    gnupg
    gnumake
    lsb-release
    nap
    neovim
    nixd
    nixfmt-rfc-style
    nushell
    openjdk17-bootstrap
    ripgrep-all
    tree
    unzip
    vim
    wezterm
    wget
    wl-clipboard
    yazi
    zellij
    zoxide
    zsh
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = false;
  };
}
