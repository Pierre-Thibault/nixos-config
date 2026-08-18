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
  inherit (userdata) username;
  secrets = config.sops.secrets;
  disque2Mount = "/mnt/disque2";
  gitMirrorDir = "${disque2Mount}/${userdata.gitMirrorSubpath}";
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
      find /home/${username} -xdev \
        -not -type l \
        -not \( -path /home/${username}/.ssh -o -path '/home/${username}/.ssh/*' \) \
        -not \( -path /home/${username}/.gnupg -o -path '/home/${username}/.gnupg/*' \) \
        -exec setfacl -m u:borgbackup:rX {} + || true
      find /home/${username} -xdev -type d \
        -not \( -path /home/${username}/.ssh -o -path '/home/${username}/.ssh/*' \) \
        -not \( -path /home/${username}/.gnupg -o -path '/home/${username}/.gnupg/*' \) \
        -exec setfacl -d -m u:borgbackup:rX {} + || true

      # open-webui (chat history, connections, RAG docs) lives outside
      # /home -- see DATA_DIR in modules/ai/ai-tools.nix -- under systemd's
      # DynamicUser convention: real state in /var/lib/private/<name>
      # (0700 root:root), with a compatibility symlink at /var/lib/<name>.
      # Grant borgbackup bare traversal on /var/lib/private itself (not
      # recursive, so sibling services like ollama stay hidden), then
      # resolve the symlink and grant read access on its real target --
      # backup-home needs that same resolved path too, since `borg create`
      # archives a symlink source argument as a symlink entry rather than
      # descending into it (verified directly, not documented behavior).
      setfacl -m u:borgbackup:X /var/lib/private
      open_webui_data=$(readlink -f /var/lib/open-webui)
      find "$open_webui_data" -xdev -not -type l \
        -exec setfacl -m u:borgbackup:rX {} + || true
      find "$open_webui_data" -xdev -type d \
        -exec setfacl -d -m u:borgbackup:rX {} + || true

      # GDM/AccountsService login-screen avatar for pierre: an actual
      # cached icon image at /var/lib/AccountsService/icons/pierre
      # (already 0644 -- no ACL needed there), plus the small config
      # file that points GDM at it, /var/lib/AccountsService/users/pierre.
      # That file alone is unreachable by default -- its parent
      # directory is 0700 root:root, unlike icons/ (0775). Without it
      # the icon image is orphaned on restore and GDM falls back to the
      # generic silhouette, as happened once on this machine already.
      setfacl -m u:borgbackup:x /var/lib/AccountsService/users
      setfacl -m u:borgbackup:r /var/lib/AccountsService/users/pierre

      # /mnt/disque2 itself (the external disk's root) is outside /home, so
      # none of the find loops above touch it, and it's not covered by
      # GitMirrors/'s own separate ACL grant below it (pre-created
      # manually, same pattern as this one). backup-home's copy_runbook
      # step writes a plain copy of the disaster-recovery runbook directly
      # there -- grant write access on this one directory (non-recursive)
      # so that succeeds instead of failing with "Permission denied" (as
      # it silently did once RUNBOOK_SRC below started pointing at a real,
      # existing file).
      setfacl -m u:borgbackup:rwx ${disque2Mount}
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
  fileSystems.${disque2Mount} = {
    device = "/dev/disk/by-uuid/77dcef31-5f83-40cf-839b-d4439adf2c6c";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=10"
    ];
  };

  # Also bind-mount at the conventional udisks2 path so it shows up in
  # Nautilus like any other drive, without giving up the system-level
  # mount above that borgbackup depends on.
  fileSystems."/run/media/${username}/Disque2" = {
    device = disque2Mount;
    fsType = "none";
    options = [
      "bind"
      "nofail"
      "x-systemd.requires-mounts-for=${disque2Mount}"
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
      pkgs.bash
      pkgs.borgbackup
      pkgs.openssh
      pkgs.git
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
      BORG_REPO = "${disque2Mount}/${userdata.borgRepoSubpath}";
      BORG_PASSCOMMAND = "cat ${secrets."borgbackup/local-repo-passphrase".path}";
      BORG_REMOTE_REPO = "ssh://wsw5tfhn@wsw5tfhn.repo.borgbase.com/./repo";
      BORG_REMOTE_PASSCOMMAND = "cat ${secrets."borgbackup/borgbase-repo-passphrase".path}";
      BORG_RSH = "env SSH_ASKPASS=${sshAskpass} SSH_ASKPASS_REQUIRE=force ssh -i ${
        secrets."borgbackup/borgbase-ssh-key".path
      } -o StrictHostKeyChecking=accept-new";
      # Offline bare git mirrors + a plain copy of the disaster-recovery
      # runbook, kept on Disque2 itself so they're readable from any live
      # OS without borg/sops tooling -- see backup-home's header comment.
      # /mnt/disque2/GitMirrors was pre-created with an ACL grant for the
      # borgbackup user (same pattern as BorgBackup/ above); /mnt/disque2
      # itself gets its own grant from fixHomeAcl (see above) so the
      # runbook copy below can write there too.
      GIT_MIRROR_DIR = gitMirrorDir;
      # backup-home defaults to $HOME/nixos-config/... for the runbook copy,
      # which is right for pierre's own manual runs but wrong here: this
      # service's $HOME is /var/lib/borgbackup (see users.users.borgbackup
      # above), not pierre's checkout -- caused a silent "not found, skipped"
      # every automated run. Point it at the real file explicitly instead.
      RUNBOOK_SRC = "/home/${username}/nixos-config/doc/disaster-recovery.md";
      # The existing mirrors under GIT_MIRROR_DIR are owned by pierre (an
      # earlier manual test run), but git here runs as borgbackup -- git's
      # safe.directory ownership check (CVE-2022-24765) refuses to operate
      # on a repo owned by a different user regardless of ACLs/permission
      # bits. Whitelisting the whole tree via env vars (no dotfile needed
      # for this system user) covers both these pre-existing mirrors and
      # any future ones borgbackup itself creates and owns.
      GIT_CONFIG_COUNT = "1";
      GIT_CONFIG_KEY_0 = "safe.directory";
      GIT_CONFIG_VALUE_0 = "${gitMirrorDir}/*";
    };
  };
}
