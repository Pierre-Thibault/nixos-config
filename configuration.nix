# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  pkgs,
  lib,
  ...
}:

let
  inherit (builtins) filter map toString;
  inherit (lib) pipe;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.strings) hasSuffix;
in
let
  userdata = import ./userdata.nix;
  import_modules = pipe ./modules [
    listFilesRecursive
    (map toString)
    (filter (hasSuffix ".nix"))
  ];
in
{
  imports = import_modules;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    systemd-boot.configurationLimit = 50;
  };

  boot.initrd.luks.devices."luks-56c4e47f-3ebd-4fac-afd8-d5c92c0e90d6".device =
    "/dev/disk/by-uuid/56c4e47f-3ebd-4fac-afd8-d5c92c0e90d6";
  networking.hostName = userdata.hostname; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_CA.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_CA.UTF-8";
    LC_IDENTIFICATION = "fr_CA.UTF-8";
    LC_MEASUREMENT = "fr_CA.UTF-8";
    LC_MONETARY = "fr_CA.UTF-8";
    LC_NAME = "fr_CA.UTF-8";
    LC_NUMERIC = "fr_CA.UTF-8";
    LC_PAPER = "fr_CA.UTF-8";
    LC_TELEPHONE = "fr_CA.UTF-8";
    LC_TIME = "fr_CA.UTF-8";
  };

  # Enable the GNOME Desktop Environment (it is xserver but in reality it is Wayland).
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    epiphany # web browser
    gnome-calculator
  ];

  environment = {
    shells = [ pkgs.zsh ];
    variables = {
      EDITOR = "hx";
      SYSTEMD_EDITOR = "hx";
      VISUAL = "hx";
    };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "ca";
    variant = "multix";
  };

  # Configure console keymap to use the xserver config
  console.useXkbConfig = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${userdata.username} = {
    isNormalUser = true;
    description = userdata.userfullname;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Install firefox.
  # programs.firefox.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = userdata.ssh_enable;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = if userdata.ssh_enable then [ 22 ] else [ ];
  networking.firewall.allowedUDPPorts = if userdata.ssh_enable then [ 22 ] else [ ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
