{ pkgs, ... }:
{
  # bluetoothd can get stuck retrying a reconnect to a trusted-but-unreachable
  # device (seen with the Beats Fit Pro, 04:9D:05:E5:48:46) right as suspend
  # is requested, delaying actual sleep entry anywhere from minutes to hours
  # (confirmed 2026-09-11 and 2026-09-12: matching
  # "avdtp_connect_cb ... Connection refused" log lines land within a
  # fraction of a millisecond of the kernel finally starting to freeze
  # processes). Powering the adapter off before sleep kills any in-flight
  # connection attempt so it can't block suspend; AutoEnable (see niri.nix)
  # would normally bring it back on resume, but we power it back on
  # explicitly here so reconnection doesn't depend on that heuristic.
  environment.etc."systemd/system-sleep/bluetooth-suspend-fix" = {
    mode = "0755";
    source = pkgs.writeShellScript "bluetooth-suspend-fix" ''
      case "$1" in
        pre)
          ${pkgs.bluez}/bin/bluetoothctl power off
          ;;
        post)
          ${pkgs.bluez}/bin/bluetoothctl power on
          ;;
      esac
    '';
  };
}
