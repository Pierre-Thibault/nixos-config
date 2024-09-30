{ config, pkgs, lib, ... }:

{
  users.users.pierre.packages = with pkgs; [
    direnv
    fanctl
    file
    gcc
    git
    gnumake
    lsb-release
    nap
    neovim
    nushell
    openjdk17-bootstrap
    ripgrep-all
    tree
    unzip
    vim
    wget
    wl-clipboard
    zsh
  ];
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
}