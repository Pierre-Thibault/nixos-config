# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  unstable,
  userdata,
  my-lib,
  ...
}:

let
  inherit (userdata) username;
in
{
  imports = (my-lib.modules ./modules);

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        memtest86.enable = true;
      };
      efi.canTouchEfiVariables = true;
    };

    kernelModules = [
      "v4l2loopback"
      "vboxdrv"
      "vboxnetflt"
      "vboxnetadp"
      "vboxpci"
      "nct6683" # Super I/O chip (Nuvoton NCT6687D) - fan/temp sensors
    ];

    # For using Droidcam:
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=2 card_label="DroidCam" exclusive_caps=1
    '';
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-utils # vainfo
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
  };

  # Configure console keymap to use the xserver config
  console = {
    useXkbConfig = true;
  };

  environment = {
    etc."geoclue/geoclue.conf" = lib.mkForce {
      source = config.sops.templates."geoclue.conf".path;
    };
    gnome.excludePackages = with pkgs; [
      epiphany # web browser
      gnome-calculator
    ];
    shells = [ pkgs.zsh ];
    systemPackages = with pkgs; [
      polkit_gnome
    ];
    variables =
      let
        editor = "hx";
      in
      {
        EDITOR = editor;
        SYSTEMD_EDITOR = editor;
        VISUAL = editor;
      };
  };

  i18n =
    let
      locale = "fr_CA.UTF-8";
    in
    {
      defaultLocale = locale;

      extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale;
        LC_MEASUREMENT = locale;
        LC_MONETARY = locale;
        LC_NAME = locale;
        LC_NUMERIC = locale;
        LC_PAPER = locale;
        LC_TELEPHONE = locale;
        LC_TIME = locale;
      };

      # Disable IBus input method completely
      inputMethod.enable = lib.mkForce false;
    };

  networking = {
    hostName = userdata.hostname; # Define your hostname.
    networkmanager = {
      enable = true;
      # Keep WiFi connection alive during suspend
      wifi = {
        powersave = false;
        scanRandMacAddress = false;
      };
    };

    # Open ports in the firewall.
    firewall =
      let
        ssh-port-list =
          if userdata.ssh_enable then
            [
              22
            ]
          else
            [
            ];
      in
      {
        allowedTCPPorts = ssh-port-list;
        allowedUDPPorts = ssh-port-list;
      };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ username ];
    # Hard-link identical files across store paths as they're added.
    auto-optimise-store = true;
  };

  programs = {
    nix-ld.enable = true; # Allow running dynamically linked binaries (npm packages, etc.)

    nix-index-database.comma.enable = true; # Add the ability to run any package by prepending its name with a comma

    dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            accent-color = "slate";
            gtk-enable-primary-paste = true;
            gtk-theme = "adw-gtk3";
            icon-theme = "breeze";
          };
        };
        locks = [
          "/org/gnome/desktop/interface/accent-color"
        ];
      }
    ];

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    steam = {
      enable = true;
    };

    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services.gtklock = { };
  };

  services = {
    displayManager = {
      gdm.enable = true;
      defaultSession = "niri";
    };
    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverrides = ''
        [org.gnome.shell]
        enabled-extensions=[]
      '';
    };

    xserver = {
      # Configure keymap in X11
      xkb = {
        layout = "ca";
        variant = "multix";
      };
    };

    # Replace the default console
    kmscon = {
      enable = true;
      package = unstable.kmscon;
      hwRender = false;
      fonts = [
        {
          name = "JetBrainsMono Nerd Font";
          package = pkgs.nerd-fonts.jetbrains-mono;
        }
      ];
      extraConfig = builtins.concatStringsSep "\n" [
        "font-size=12"
        "xkb-layout=ca"
        "xkb-variant=multix"
      ];
    };

    # Enable CUPS to print documents.
    printing.enable = true;

    # Enable sound with pipewire.
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;

      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
    pcscd.enable = true;

    # Enable the OpenSSH daemon.
    openssh.enable = userdata.ssh_enable;

    geoclue2 = {
      enable = true;
      appConfig = {
        "xdg-desktop-portal" = {
          isAllowed = true;
          isSystem = true;
        };
        "get-location" = {
          isAllowed = true;
          isSystem = true;
        };
      };
    };

    earlyoom = {
      enable = true;
      freeMemThreshold = 5;
      freeSwapThreshold = 10;
      enableNotifications = true; # notifie via systemd-oomd/notify
    };

  };

  # Hack to make OBS work on Niri:
  systemd.user.services.xdg-desktop-portal-wlr = {
    environment = {
      XDG_CURRENT_DESKTOP = "sway";
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true; # Important pour Niri
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [
      "gtk"
      "wlr"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  time.timeZone = "America/New_York";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = userdata.userfullname;
    extraGroups = [
      "i2c" # ddcutil: monitor brightness control via DDC/CI
      "networkmanager"
      "video"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
}
