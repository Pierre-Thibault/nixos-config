{
  pkgs,
  ...
}:

{
  # Enable Niri
  programs.niri = {
    enable = true;
  };

  # Enable XDG portal for screen sharing and other desktop integration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };

  # Essential packages for Niri based on Hyprland configuration
  environment.systemPackages = with pkgs; [
    # Core Niri utilities
    niri # The compositor itself

    # Wallpaper utility
    swaybg # Background setter for Wayland (Niri compatible)

    # Screen locker
    swaylock-effects # Screen locker with effects

    # Idle daemon
    swayidle # Idle management daemon

    # Color picker
    hyprpicker # Works with any Wayland compositor

    # Wayland utilities
    wayland
    wayland-protocols
    wayland-utils
    wl-clipboard # Command-line clipboard utilities

    # Status bar
    waybar # Status bar with workspace support

    # App launcher
    # Note: ulauncher is already in modules/programs.nix

    # Emoji picker
    wofi-emoji # Emoji picker for Wayland

    # Notifications
    swaynotificationcenter # Notification center with history
    libnotify # For notify-send command

    # Terminal (Ghostty, already configured)
    # Note: ghostty is already in your configuration

    # Screenshots
    grim # Screenshot utility
    slurp # Select a region
    swappy # Screenshot editor

    # Network management
    networkmanagerapplet # Network manager applet
    networkmanager_dmenu # Alternative dmenu interface

    # Audio control
    pavucontrol # PulseAudio volume control
    # Note: Using pactl from pipewire-pulse

    # Brightness control
    brightnessctl # Backlight control

    # Color temperature / blue light filter
    wlsunset # Automatic color temperature adjustment

    # Power menu
    wlogout # Graphical logout/power menu

    # Bluetooth
    blueman # Bluetooth manager
    bluez # Bluetooth support

    # Display configuration
    wlr-randr # Display configuration

    # Authentication agent
    polkit_gnome # Polkit authentication agent

    # Launcher
    fuzzel
  ];

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  # Enable Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Configure session variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Enable Wayland support in Electron/Chromium apps
  };

  # Fonts for better rendering (especially for waybar icons)
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];
}
