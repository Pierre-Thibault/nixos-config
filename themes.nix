{ config, pkgs, lib, ... }:

{
  users.users.pierre.packages = with pkgs; [
    ant-theme
    graphite-gtk-theme
    whitesur-cursors
    whitesur-gtk-theme
    whitesur-icon-theme  
  ];
}