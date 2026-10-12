# modules/gui/niri.nix
{ pkgs, ... }:
let
  # Tecla with readable level labels (Maj, AltGr…) instead of 1, 2, 3…
  tecla-patched = pkgs.gnome-tecla.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./tecla-level-labels.patch ];
  });
in
{
  environment.systemPackages = [ tecla-patched ];
}
