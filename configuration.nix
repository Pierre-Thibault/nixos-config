# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports = lib.pipe ./services [
    builtins.readDir
    (lib.filterAttrs (name: _: lib.hasSuffix ".nix" name))
    (lib.mapAttrsToList (name: _: ./services + "/${name}"))
   ] ++ [
    ./cli_commands.nix
    ./gnome_extensions.nix
    ./programs.nix
    ./system_lib.nix
    ./system_packages.nix
    ./themes.nix
    ./user_lib.nix
    # Include the results of the hardware scan
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-56c4e47f-3ebd-4fac-afd8-d5c92c0e90d6".device = "/dev/disk/by-uuid/56c4e47f-3ebd-4fac-afd8-d5c92c0e90d6";
  networking.hostName = "pierre-nixos"; # Define your hostname.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "ca";
    variant = "multix";
  };

  # Configure console keymap
  console.keyMap = "cf";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
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

  services.flatpak.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pierre = {
    isNormalUser = true;
    description = "Pierre Thibault";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  # Install firefox.
  programs.firefox.enable = true;

  programs.zsh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
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