# Isolated system user for home backups. Motivation: BORG_PASSCOMMAND via
# secret-tool put the borg/BorgBase credentials in pierre's own GNOME
# keyring, readable by *any* process running under pierre's UID (no
# per-program ACL on the D-Bus Secret Service). Moving the credentials to
# a dedicated, unprivileged system user with sops-decrypted, 0400 files
# gives real UID-based isolation instead.
#
# See doc/disaster-recovery.md for the manual restore path (still pierre,
# Disque2 only -- see bin/restore-home in this repo).
{
  config,
  pkgs,
  lib,
  self,
  userdata,
  ...
}:

let
  secrets = config.sops.secrets;
  sshAskpass = pkgs.writeShellScript "borgbackup-ssh-askpass" ''
    exec cat ${secrets."borgbackup/borgbase-ssh-key-passphrase".path}
  '';
  # A previous version of this used a declarative systemd.tmpfiles `A+`
  # rule instead, applied at every activation/boot. Dropped in favor of
  # the ExecStartPre below: the tmpfiles version recurses into the whole
  # home tree unconditionally at boot time regardless of whether a backup
  # ever runs, including the two problem spots below, and separately its
  # walk into the rclone FUSE mounts at ~/icloud and ~/proton ("Operation
  # not supported" for ACLs there) could leave things incomplete and the
  # ACL mask on /home/pierre itself reset to nothing (NixOS's own
  # user-activation chmods the home dir on every switch, rewriting the
  # mask and silently defeating the grant). An ExecStartPre (root, via
  # the `+` prefix) right before every backup sidesteps activation-order
  # dependence entirely.
  fixHomeAcl = pkgs.writeShellApplication {
    name = "borgbackup-fix-home-acl";
    # ExecStartPre scripts don't inherit an interactive shell's PATH --
    # this silently no-op'd via "find: 'setfacl': No such file or
    # directory" the first time. runtimeInputs makes the dependency
    # explicit instead of relying on the ambient environment.
    runtimeInputs = [
      pkgs.acl
      pkgs.findutils
    ];
    text = ''
      # -xdev: mirrors backup-home's own --one-file-system, so this never
      # needs the rclone FUSE mounts (~/icloud, ~/proton -- ACLs
      # unsupported there anyway).
      #
      # -not -type l: setfacl follows symlinks by default and applies the
      # ACL to their *target* -- a stray symlink under /home/pierre
      # pointing at /dev/null once caused this to silently restrict
      # /dev/null itself to read-only for borgbackup, system-wide.
      #
      # ~/.ssh and ~/.gnupg excluded: granting borgbackup a named ACL
      # entry forces POSIX ACL to recalculate the file's mask, and that
      # mask is what stat() reports as the "group" permission bits -- so
      # ssh/gpg would see e.g. 640 instead of 600 on private keys and
      # refuse/warn. backup-home mirrors this exclusion (BORG_EXCLUDE_CREDENTIALS
      # below) so these still get backed up normally via pierre's own
      # manual runs, just not the automated one.
      find /home/pierre -xdev \
        -not -type l \
        -not \( -path /home/pierre/.ssh -o -path '/home/pierre/.ssh/*' \) \
        -not \( -path /home/pierre/.gnupg -o -path '/home/pierre/.gnupg/*' \) \
        -exec setfacl -m u:borgbackup:rX {} + || true
      find /home/pierre -xdev -type d \
        -not \( -path /home/pierre/.ssh -o -path '/home/pierre/.ssh/*' \) \
        -not \( -path /home/pierre/.gnupg -o -path '/home/pierre/.gnupg/*' \) \
        -exec setfacl -d -m u:borgbackup:rX {} + || true
    '';
  };
in
{
  users.groups.borgbackup = { };
  users.users.borgbackup = {
    isSystemUser = true;
    group = "borgbackup";
    home = "/var/lib/borgbackup";
    createHome = true;
    # Not meant for interactive login -- just lets `sudo -u borgbackup -i`
    # work for debugging.
    shell = pkgs.bash;
  };

  # /home/pierre is mode 700; borgbackup can only read into it via a
  # targeted ACL -- see fixHomeAcl above (applied per-run via
  # ExecStartPre, not declaratively here; see its comment for why).

  environment.etc."borgbackup/backup-home" = {
    source = self + "/bin/backup-home";
    mode = "0555";
  };

  # Disque2 is permanently attached; mount it at the system level (instead
  # of relying on pierre's session-scoped udisks2 automount at
  # /run/media/pierre/Disque2) so the borgbackup service can reach it
  # headlessly, independent of any logged-in graphical session.
  fileSystems."/mnt/disque2" = {
    device = "/dev/disk/by-uuid/77dcef31-5f83-40cf-839b-d4439adf2c6c";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=10"
    ];
  };

  # Core backup action -- just this, nothing else. Triggerable manually
  # (`systemctl start borgbackup.service`) for testing without any of the
  # email/suspend side effects that come with the scheduled wrapper; see
  # borgbackup-nightly.nix for the timer that drives this automatically.
  systemd.services.borgbackup = lib.mkIf userdata.enableSops {
    description = "Home backup (borg) as the isolated borgbackup user";
    after = [
      "mnt-disque2.mount"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "mnt-disque2.mount" ];
    path = [
      pkgs.borgbackup
      pkgs.openssh
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "borgbackup";
      Group = "borgbackup";
      # "+" runs this specific step as root regardless of User=/Group=
      # above -- see fixHomeAcl comment for why this is needed every run.
      ExecStartPre = "+${fixHomeAcl}/bin/borgbackup-fix-home-acl";
      ExecStart = "/etc/borgbackup/backup-home";
    };
    environment = {
      # See fixHomeAcl comment: keeps ~/.ssh and ~/.gnupg out of both the
      # ACL grant and this automated backup, since granting the ACL is
      # what breaks their permissions as seen by ssh/gpg.
      BORG_EXCLUDE_CREDENTIALS = "1";
      BORG_REPO = "/mnt/disque2/BorgBackup/backup-pierre-pierre-nixos";
      BORG_PASSCOMMAND = "cat ${secrets."borgbackup/local-repo-passphrase".path}";
      BORG_REMOTE_REPO = "ssh://wsw5tfhn@wsw5tfhn.repo.borgbase.com/./repo";
      BORG_REMOTE_PASSCOMMAND = "cat ${secrets."borgbackup/borgbase-repo-passphrase".path}";
      BORG_RSH = "env SSH_ASKPASS=${sshAskpass} SSH_ASKPASS_REQUIRE=force ssh -i ${
        secrets."borgbackup/borgbase-ssh-key".path
      } -o StrictHostKeyChecking=accept-new";
    };
  };
}
