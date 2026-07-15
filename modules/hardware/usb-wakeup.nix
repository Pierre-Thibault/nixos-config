{ ... }:
{
  # Logitech Bolt USB receiver (046d:c548) - disable USB remote wakeup.
  # Was spuriously waking the system from suspend within seconds of entering
  # sleep (confirmed 2026-07-12: unplugging the dongle stopped the immediate
  # wake, and disabling power/wakeup on it live fixed it without disabling
  # keyboard wakeup).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", ATTR{power/wakeup}="disabled"
  '';
}
