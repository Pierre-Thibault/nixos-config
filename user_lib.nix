{ config, pkgs, lib, ... }:

{
  users.users.pierre.packages = with pkgs; [
  ];
}