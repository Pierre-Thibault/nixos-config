# Static, non-secret environment variables exposed system-wide via
# environment.sessionVariables (see configuration.nix). These are set by
# PAM at login, before any shell starts, so they reach every shell (zsh,
# bash, fish...) and GUI apps launched from the niri session alike --
# unlike exports in ~/dotfiles/zsh/.zshrc, which only apply to zsh.
#
# Attribute names are lowercase here for easier editing; configuration.nix
# uppercases them (lib.toUpper) when building the actual env var names.
#
# PATH entries for ~/bin and ~/.local/bin are handled separately via the
# dedicated environment.homeBinInPath / environment.localBinInPath options;
# this file only adds the extra directories those options don't cover.
{ userdata }:
let
  inherit (userdata) username;
in
{
  libva_driver_name = "radeonsi";

  xcursor_theme = "Adwaita";

  gopath = "$HOME/.local/share/go";

  sops_age_key_cmd = "age -d $HOME/.config/sops/age/keys.txt.age";

  # Off-site BorgBase backup now runs exclusively as the borgbackup system
  # user (see modules/backup/) -- pierre's session no longer has passive
  # access to that repo's passphrase or SSH key. These variables are for
  # pierre's own local/manual borg usage against Disque2 only.
  borg_repo = "/run/media/${username}/Disque2/BorgBackup/backup-${username}-${userdata.hostname}";
  borg_passcommand = "$HOME/bin/borg-ask-passphrase";

  git_mirror_dir = "/run/media/${username}/Disque2/GitMirrors";

  # Placeholders so ovhcloud-cli/pulumi_ovh see all 4 expected env vars and
  # skip straight to requests instead of prompting for `login` -- the real
  # values live only in the ovh-proxy Caddy service's own environment
  # (modules/ovh-proxy.nix), which overwrites these before forwarding to
  # OVH's real API. Never real credentials, same idea as
  # digitalocean:token = "proxy" for DO.
  ovh_application_key = "dummy";
  ovh_application_secret = "dummy";
  ovh_consumer_key = "dummy";

  path = [
    "$HOME/nixos-config/bin"
    "$HOME/.local/share/go/bin"
  ];
}
