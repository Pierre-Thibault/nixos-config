{
  pkgs,
  unstable,
  userdata,
  ...
}:

{
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
    printing.drivers = [ pkgs.brlaser ]; # Brother HL-2240

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
    openssh.enable = userdata.sshEnable;

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

    # Auto-unlock the login keyring (SSH keys, secrets) at GDM login.
    # Without this, gdm-password's PAM stack never unlocks it, and
    # gcr-ssh-agent has no working prompter under Niri to ask for the
    # keyring password -- ssh/git just hang forever. Found 2026-08-06.
    gnome.gnome-keyring.enable = true;
  };
}
