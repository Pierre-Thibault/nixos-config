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
  # The declarative ACL below (systemd.tmpfiles A+) recurses into the whole
  # home tree, including the rclone FUSE mounts at ~/icloud and ~/proton --
  # those don't support POSIX ACLs ("Operation not supported"), which can
  # leave the walk incomplete and the ACL mask on /home/pierre itself
  # reset to nothing (observed in practice: NixOS's own user-activation
  # step chmods the home dir on every switch, which rewrites the ACL mask
  # and silently defeats the grant to borgbackup). `-xdev` skips crossing
  # into those mounts, mirroring backup-home's own --one-file-system, so
  # this never needed them anyway. Re-run as an ExecStartPre (root, via
  # the `+` prefix) right before every backup, rather than trusting
  # activation ordering to get this right on its own.
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
      find /home/pierre -xdev -exec setfacl -m u:borgbackup:rX {} + || true
      find /home/pierre -xdev -type d -exec setfacl -d -m u:borgbackup:rX {} + || true
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
  # targeted ACL. `A+` = set POSIX ACL entries recursively, keeping
  # everything else about the base 700 mode unchanged; the `d:` entry is a
  # default ACL so files created later inherit the same read grant.
  # Re-applied idempotently by systemd-tmpfiles at every activation/boot.
  systemd.tmpfiles.rules = [
    "A+ /home/pierre - - - - u:borgbackup:rX,d:u:borgbackup:rX"
  ];

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

  # Manually triggerable for now (`systemctl start borgbackup-nightly`);
  # the nightly timer is a separate follow-up once this is validated.
  systemd.services.borgbackup-nightly = lib.mkIf userdata.enableSops {
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
