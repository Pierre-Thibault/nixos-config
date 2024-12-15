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
    gitleaks
    gnupg
    gnumake
    helix
    lsb-release
    mc
    nap
    neofetch
    neovim
    nixd
    nixfmt-rfc-style
    nushell
    openjdk17-bootstrap
    ripgrep-all
    stow
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
