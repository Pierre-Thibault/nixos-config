# sops-nix configuration for iCloud credentials.
{ self, userdata, ... }:
{
  sops.secrets.ICLOUD_PASSWORD = {
    sopsFile = self + "/sops/secrets.yaml";
    owner = userdata.username;
    path = "/run/secrets/icloud-password";
  };
}
