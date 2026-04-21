{
  pkgs,
  ...
}:

{
  # Enable Niri
  programs.niri = {
    enable = true;
  };

  # Enable XWayland for X11 apps (gparted, etc.)
  programs.xwayland.enable = true;

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

    # Idle daemon
    hypridle # Idle management daemon
    gtklock # GTK-based screen locker
    playerctl # Media player control (for video idle detection)

    # Color picker
    hyprpicker # Works with any Wayland compositor

    # Wayland utilities
    wayland
    wayland-protocols
    wayland-utils
    wl-clipboard # Command-line clipboard utilities

    # Status bar
    waybar # Status bar with workspace support

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
    rofi

    # OSD (On-Screen Display) for volume and brightness
    swayosd

    # Screen temperature
    redland-wayland

    # Ambient light / backlight auto-adjustment
    clight
    clightd
  ];

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  # Start polkit authentication agent with graphical session
  systemd.user.services.polkit-gnome = {
    description = "Polkit GNOME Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Add dependencies to hypridle service PATH for scripts
  systemd.user.services.hypridle = {
    path = with pkgs; [
      bash
      coreutils # sleep
      procps # pkill
    ];
    # Prevent hypridle from running for gdm-greeter (no config file there)
    unitConfig.ConditionUser = "!gdm-greeter";
    serviceConfig = {
      # Delay startup to let Wayland compositor fully initialize
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
    };
  };

  # Enable Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Enable all Bluetooth profiles
        Enable = "Source,Sink,Media,Socket";
        # Reconnect automatically after suspend
        AutoEnable = true;
        # Delay before resuming (in seconds)
        ResumeDelay = 2;
      };
    };
  };
  services.blueman.enable = true;

  # clightd D-Bus system service (no NixOS module exists for it)
  services.dbus.packages = [ pkgs.clightd ];

  systemd.services.clightd = {
    description = "Bus service to manage screen brightness/gamma/dpms";
    requires = [ "polkit.service" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type       = "dbus";
      BusName    = "org.clightd.clightd";
      User       = "root";
      ExecStart  = "${pkgs.clightd}/libexec/clightd";
      Restart    = "on-failure";
      RestartSec = 5;
      Environment = [
        "CLIGHTD_BL_VCP=0x10"
        "CLIGHTD_BL_SYSFS_ENABLED=1"
        "CLIGHTD_BL_DDC_ENABLED=1"
        "CLIGHTD_BL_EMULATED_ENABLED=1"
        "CLIGHTD_PIPEWIRE_RUNTIME_DIR=/run/user/1000/"
        # Needed so clightd (running as root) can find the Wayland socket for gamma
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
    };
    wantedBy = [ "multi-user.target" ];
  };

  # i2c-dev needed by clightd and ddcutil for DDC monitor control
  hardware.i2c.enable = true;

  # Configure session variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Enable Wayland support in Electron/Chromium apps
  };

  # Fonts for better rendering (especially for waybar icons)
  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];
}
