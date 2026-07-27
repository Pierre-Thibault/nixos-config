# sops-nix configuration for iCloud credentials.
{ self, userdata, lib, ... }:
{
  sops.secrets = lib.optionalAttrs userdata.enableSops {
    ICLOUD_PASSWORD = {
      sopsFile = self + "/sops/secrets.yaml";
      owner = userdata.username;
      path = "/run/secrets/icloud-password";
    };
  };
}
