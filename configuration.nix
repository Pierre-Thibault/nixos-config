# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  pkgs,
  lib,
  nixos-25-05,
  ...
}:

let
  inherit (builtins) filter map toString;
  inherit (lib) pipe;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.strings) hasSuffix;
  userdata = import ./userdata.nix;
  inherit (userdata) username;
  modules = pipe ./modules [
    listFilesRecursive
    (map toString)
    (filter (hasSuffix ".nix"))
  ];
in
{
  imports = modules;

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 50;
      };
      efi.canTouchEfiVariables = true;
    };

    initrd.luks.devices."luks-56c4e47f-3ebd-4fac-afd8-d5c92c0e90d6".device =
      "/dev/disk/by-uuid/56c4e47f-3ebd-4fac-afd8-d5c92c0e90d6";

    kernelModules = [
      "vboxdrv"
      "vboxnetflt"
      "vboxnetadp"
      "vboxpci"
    ];
  };

  # Configure console keymap to use the xserver config
  console.useXkbConfig = true;

  environment = {
    gnome.excludePackages = with nixos-25-05.pkgs; [
      epiphany # web browser
      gnome-calculator
    ];
    shells = [ pkgs.zsh ];
    systemPackages = with nixos-25-05.pkgs; [
      gnome-shell
      gnome-control-center
      gnome-settings-daemon
      mutter
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
    networkmanager.enable = true;

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
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs = {
    dconf.profiles.user.databases = [
      {
        lockAll = true; # prevents overriding
        settings = {
          "org/gnome/desktop/interface" = {
            accent-color = "slate";
          };
        };
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

  security.rtkit.enable = true;

  services = {
    xserver = {
      # Enable the GNOME Desktop Environment (it is xserver but in reality it is Wayland).
      displayManager.gdm.enable = true;
      desktopManager.gnome = {
        enable = true;
        # Use Gnome 48 from 25.05
        extraGSettingsOverrides = ''
          [org.gnome.shell]
          enabled-extensions=[]
        '';
      };

      # Configure keymap in X11
      xkb = {
        layout = "ca";
        variant = "multix";
      };
    };

    desktopManager.plasma6.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;

    # Enable sound with pipewire.
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
    pcscd.enable = true;

    # Enable the OpenSSH daemon.
    openssh.enable = userdata.ssh_enable;
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
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
}
