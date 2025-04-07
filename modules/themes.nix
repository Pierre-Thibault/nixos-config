{ config, pkgs, lib, ... }:

let userdata = import ../userdata.nix; in
{
  users.users.${userdata.username}.packages = with pkgs; [
    ant-theme
    graphite-gtk-theme
    whitesur-cursors
    whitesur-gtk-theme
    whitesur-icon-theme  
  ];
}