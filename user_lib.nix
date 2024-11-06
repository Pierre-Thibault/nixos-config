{ config, pkgs, lib, ... }:

let userdata = import ./userdata.nix; in
{
  users.users.${userdata.username}.packages = with pkgs; [
    hunspell
    hunspellDicts.en-ca
    hunspellDicts.en-gb-ise
    hunspellDicts.en-us
    hunspellDicts.fr-any
    hunspellDicts.fr-classic
    hunspellDicts.fr-moderne
    hunspellDicts.es-mx
    languagetool
  ];
}

