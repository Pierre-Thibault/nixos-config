{ config, pkgs, lib, ... }:

let userdata = import ./userdata.nix; in
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
