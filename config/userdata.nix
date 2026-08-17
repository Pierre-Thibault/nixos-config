# Update with what you need
rec {
  username = "pierre";
  userfullname = "Pierre Thibault";
  hostname = "pierre-nixos";
  sshEnable = false;
  enableCaddyProxy = true;
  # Set to false, temporarily, when bootstrapping sops on a machine
  # whose age identity isn't in .sops.yaml yet — see
  # doc/disaster-recovery.md. Gates every sops.secrets/sops.templates
  # declaration across the config; without it, a missing recipient makes
  # decryption fail and *nixos-rebuild switch* fails outright, not just
  # the affected service.
  enableSops = true;

  # SMTP relay for scripted notifications (currently just
  # borgbackup-nightly.nix). Host/port aren't personal data, kept here;
  # smtp_user/notify_email (email addresses) and the password all went to
  # sops/borgbackup.yaml instead -- this file is committed to a public
  # repo.
  smtpHost = "smtp.protonmail.ch";
  smtpPort = 587;

  # Disque2 (external backup drive) is reachable at two different mount
  # points -- system-wide at /mnt/disque2 (modules/backup/borgbackup.nix,
  # so the isolated borgbackup service can reach it headlessly) and at the
  # conventional udisks2 session path (config/environment-variables.nix,
  # for pierre's own manual borg/git-mirror commands) -- but both refer to
  # the same physical directories underneath. Centralizing just these
  # subpaths here means the two mount-point-specific files each supply
  # their own prefix instead of separately hardcoding the same suffix.
  borgRepoSubpath = "BorgBackup/backup-${username}-${hostname}";
  gitMirrorSubpath = "GitMirrors";
}
