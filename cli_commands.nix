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
    bat
    direnv
    fanctl
    file
    fzf
    gcc
    git
    gnupg
    gnumake
    helix
    lsb-release
    mc
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
