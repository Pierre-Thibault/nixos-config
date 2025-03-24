{
  config,
  pkgs,
  lib,
  ...
}:

let
  userdata = import ./userdata.nix;
in
# unstable = import <nixos-unstable> {
#   config = {
#     allowUnfree = true;
#   };
# };
{
  users.users.${userdata.username}.packages = with pkgs; [
    bat
    direnv
    fanctl
    file
    fzf
    gcc
    ghostty
    git
    gitleaks
    gnupg
    gnumake
    helix
    lsb-release
    lsd
    lsp-ai
    marksman
    mc
    nap
    neofetch
    neovim
    nixd
    nixfmt-rfc-style
    nushell
    openjdk17-bootstrap
    ripgrep
    ripgrep-all
    stow
    tree
    unzip
    vim
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
