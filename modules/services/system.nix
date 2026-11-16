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

    # kmscon replaced the default console (TrueType/Nerd Font rendering
    # via DRM) but its DRM master handoff on VT switch hangs the system
    # hard, requiring a physical reset — confirmed 2026-08-20 by
    # reproducing the freeze with kmscon on and it going away with it
    # off. Plain agetty doesn't touch DRM, so it's safe. Loses the nice
    # font/icons; no fix found yet, just disabled.
    kmscon = {
      enable = false;
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
