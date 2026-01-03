{
  pkgs,
  lib,
  ...
}:

{
  # Service that listens for resume events via D-Bus
  systemd.user.services.espanso-dbus-resume = {
    enable = true;
    description = "Restart Espanso on resume (D-Bus triggered)";
    serviceConfig = {
      Type = "simple";
      Restart = "always";
    };
    script = lib.getExe (
      pkgs.writeShellApplication {
        name = "espanso-dbus-resume-listener";
        runtimeInputs = with pkgs; [
          dbus
          systemd
        ];
        text = ''
          # Monitor D-Bus for PrepareForSleep signal from systemd-logind
          dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" |
          while read -r line; do
            # PrepareForSleep signal has a boolean argument:
            # - true means going to sleep
            # - false means resuming from sleep
            if echo "$line" | grep -q "boolean false"; then
              # System is resuming - wait for session to be ready
              sleep 8

              # Restart Espanso systemd service
              systemctl --user restart espanso.service
            fi
          done
        '';
      }
    );
    wantedBy = [ "default.target" ];
  };

  # Watchdog that checks every 30 seconds if Espanso is running
  systemd.user.services.espanso-watchdog = {
    enable = true;
    description = "Espanso watchdog - restart if not running";
    serviceConfig = {
      Type = "oneshot";
    };
    script = lib.getExe (
      pkgs.writeShellApplication {
        name = "espanso-watchdog";
        runtimeInputs = with pkgs; [ systemd ];
        text = ''
          # Check if Espanso service is active
          if ! systemctl --user is-active --quiet espanso.service; then
            # Service is not active, restart it
            systemctl --user restart espanso.service
          fi
        '';
      }
    );
  };

  # Timer that runs the watchdog every 30 seconds
  systemd.user.timers.espanso-watchdog = {
    enable = true;
    description = "Run Espanso watchdog periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      Unit = "espanso-watchdog.service";
    };
  };
}
