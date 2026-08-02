# Scheduled wrapper around the core backup (borgbackup.nix,
# `systemd.services.borgbackup`) -- kept in a separate service/file so
# manual testing of the backup itself stays exactly as simple as before
# (`systemctl start borgbackup.service`, no email, no suspend). This one
# adds the "nightly" behavior: wake from suspend to run at 4am, no
# catch-up if the machine was off, email the result, and suspend again
# afterward if nobody's using the machine.
{
  config,
  pkgs,
  lib,
  userdata,
  ...
}:

let
  secrets = config.sops.secrets;
  borgbackupNightly = pkgs.writeShellApplication {
    name = "borgbackup-nightly";
    runtimeInputs = [
      pkgs.systemd
      pkgs.msmtp
      pkgs.coreutils
      pkgs.gawk
    ];
    text = ''
      # smtp_user/notify_email are sops secrets (email addresses --
      # nixos-config is a public repo), read at runtime rather than
      # baked into this script at build time like smtpHost/smtpPort
      # (host/port aren't personal data, so those stay plain nix values
      # from userdata.nix).
      smtp_user=$(cat ${secrets."borgbackup/smtp-user".path})
      notify_email=$(cat ${secrets."borgbackup/notify-email".path})

      # Scope the emailed log to just this run. A prior attempt used the
      # service's InvocationID via `systemctl show`, but that property
      # reads back empty once the (Type=oneshot) unit has already
      # exited -- confirmed empty even moments after a run finishes, not
      # just after the next one starts. A timestamp captured just before
      # starting is simpler and doesn't depend on state systemd doesn't
      # actually keep around.
      run_start=$(date '+%Y-%m-%d %H:%M:%S')
      rc=0
      systemctl start --wait borgbackup.service || rc=$?

      if [ "$rc" -eq 0 ]; then
        subject="[borgbackup] Succès - $(date +%Y-%m-%d)"
      else
        subject="[borgbackup] ÉCHEC (code $rc) - $(date +%Y-%m-%d)"
      fi

      {
        echo "Subject: $subject"
        echo "From: $smtp_user"
        echo "To: $notify_email"
        echo
        journalctl -u borgbackup.service --since "$run_start" --no-pager
      } | msmtp \
            --host=${userdata.smtpHost} --port=${toString userdata.smtpPort} \
            --tls=on --tls-starttls=on \
            --auth=on --user="$smtp_user" \
            --passwordeval="cat ${secrets."borgbackup/smtp-password".path}" \
            --from="$smtp_user" \
            "$notify_email" \
        || echo "Warning: failed to send notification email." >&2

      # Only after the email attempt is fully done (msmtp above is
      # synchronous) -- suspending must never be able to happen first.
      active=0
      while read -r s; do
        state=$(loginctl show-session "$s" -p State --value 2>/dev/null || echo "")
        if [ "$state" = "active" ]; then
          active=1
          break
        fi
      done < <(loginctl list-sessions --no-legend | awk '{print $1}')

      if [ "$active" -eq 0 ]; then
        systemctl suspend
      fi

      exit "$rc"
    '';
  };
in
{
  systemd.services.borgbackup-nightly = lib.mkIf userdata.enableSops {
    description = "Nightly borgbackup run: email result, suspend if idle";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${borgbackupNightly}/bin/borgbackup-nightly";
    };
  };

  systemd.timers.borgbackup-nightly = lib.mkIf userdata.enableSops {
    description = "Trigger the nightly borgbackup run at 4am";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:00";
      # No catch-up run if the machine was off at 4am -- explicitly not
      # wanted (see plan discussion).
      Persistent = false;
      # Wake from suspend via RTC alarm to run even if asleep at 4am.
      WakeSystem = true;
    };
  };
}
