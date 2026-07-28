# sops-nix configuration for the borgbackup system user's credentials.
# Decrypted automatically at activation via the machine's own age identity
# (no interactive unlock needed) straight to files owned by borgbackup,
# mode 0400 -- isolated from pierre's own session/keyring on purpose. See
# doc/disaster-recovery.md and the borgbackup-user-isolation design notes
# for context.
{ self, userdata, lib, ... }:
{
  sops.secrets = lib.optionalAttrs userdata.enableSops {
    "borgbackup/local-repo-passphrase" = {
      sopsFile = self + "/sops/borgbackup.yaml";
      key = "local_repo_passphrase";
      owner = "borgbackup";
      mode = "0400";
    };
    "borgbackup/borgbase-repo-passphrase" = {
      sopsFile = self + "/sops/borgbackup.yaml";
      key = "borgbase_repo_passphrase";
      owner = "borgbackup";
      mode = "0400";
    };
    "borgbackup/borgbase-ssh-key" = {
      sopsFile = self + "/sops/borgbackup.yaml";
      key = "borgbase_ssh_key";
      owner = "borgbackup";
      mode = "0400";
    };
    "borgbackup/borgbase-ssh-key-passphrase" = {
      sopsFile = self + "/sops/borgbackup.yaml";
      key = "borgbase_ssh_key_passphrase";
      owner = "borgbackup";
      mode = "0400";
    };
  };
}
