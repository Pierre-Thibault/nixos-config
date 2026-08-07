{
  pkgs,
  self,
  ...
}:

{
  # Enable Niri
  programs.niri = {
    enable = true;
  };

  # waybar's pulseaudio module throws std::runtime_error from inside a
  # libpulse C callback when pipewire-pulse restarts (e.g. during a
  # nixos-rebuild switch reload), which std::terminate()s the whole bar.
  # This SIGABRTs waybar.service, and since it has KillMode=mixed, that
  # SIGKILLs any process left in its cgroup -- including an active gtklock
  # instance, corrupting the screen (found + fixed 2026-08-06/07).
  # Fixed upstream on master (Alexays/Waybar@3831524, closes #5141) but not
  # yet in a tagged release; nixpkgs pins the 0.15.0 tag. Upstream's diff
  # doesn't apply to 0.15.0 (later commits changed the surrounding code), so
  # this patch reimplements the same fix against the 0.15.0 source.
  nixpkgs.overlays = [
    (_final: prev: {
      waybar = prev.waybar.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./waybar-audio-crash-fix.patch ];
      });
    })
  ];

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
  ];

  # gcr-ssh-agent (from services.desktopManager.gnome) depends on
  # org.gnome.keyring.SystemPrompter, a legacy X11-only prompter from gcr
  # 3.41.2 -- it fails with "cannot open display" under Niri regardless of
  # WAYLAND_DISPLAY/DISPLAY being set, and gcr-ssh-agent's retry fallback
  # then spins ssh-add at ~100% CPU forever instead of prompting. No newer
  # gcr_4 fixes this (checked nixos-unstable: still 4.4.0.1, same bug).
  # Replaced with plain OpenSSH ssh-agent + a rofi-based askpass.
  # Found 2026-08-06.
  services.gnome.gcr-ssh-agent.enable = false;

  # Battle-tested built-in replacement (nixos/modules/programs/ssh.nix):
  # spawns systemd.user.services.ssh-agent, wires SSH_AUTH_SOCK into shells
  # via environment.extraInit, and sets SSH_ASKPASS globally -- only used
  # by ssh/ssh-add when no controlling terminal is attached.
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
    askPassword = "${self}/bin/ssh-askpass-rofi";
  };

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

  # Workspace MRU daemon — tracks workspace focus history for niri-workspace-switch
  systemd.user.services.niri-workspace-mru-daemon = {
    description = "Niri workspace MRU tracker";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = [
      pkgs.python3
      pkgs.niri
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${self}/bin/niri-workspace-mru-daemon";
      Restart = "on-failure";
      RestartSec = 2;
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

  # i2c-dev needed by ddcutil for DDC monitor control
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
