{
  pkgs,
  userdata,
  ...
}:

let
  # CopyQ sans le plugin de chiffrement GnuPG (cause un timeout de 10s au démarrage)
  copyq-no-encrypt = pkgs.copyq.overrideAttrs (oldAttrs: {
    cmakeFlags = oldAttrs.cmakeFlags ++ [ "-DWITH_ITEM_ENCRYPT=OFF" ];
  });

  # Wrapper pour CopyQ qui ignore le thème Qt global
  copyq-wrapped = pkgs.symlinkJoin {
    name = "copyq-wrapped";
    paths = [ copyq-no-encrypt ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/copyq \
        --unset QT_QPA_PLATFORMTHEME \
        --unset QT_STYLE_OVERRIDE
    '';
  };

  # Discord's bundled MediaPipe library opens its segmentation model file
  # O_RDWR, which fails against the read-only Nix store since nixpkgs stages
  # discord_voice as a plain symlink there. This breaks video background
  # effects (camera renders black). See
  # https://github.com/NixOS/nixpkgs/issues/543857
  # Workaround: poll in the background right after launch and, as soon as
  # nixpkgs' own discord-stage-modules script (re)creates the discord_voice
  # symlink, replace it with a writable copy.
  discord-wrapped = pkgs.symlinkJoin {
    name = "discord-wrapped";
    paths = [ pkgs.discord ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/discord --run '
        (
          for _ in $(seq 1 50); do
            for d in "$HOME"/.config/discord/*/modules/discord_voice; do
              if [ -L "$d" ]; then
                target=$(readlink -f "$d")
                rm -f "$d"
                cp -rL "$target" "$d"
                chmod -R u+w "$d"
              fi
            done
            sleep 0.2
          done
        ) &
        disown
      '
      rm -f $out/bin/Discord
      ln -s discord $out/bin/Discord
    '';
  };

in
{
  users.users.${userdata.username}.packages = with pkgs; [
    anki
    audacity
    (brave.override {
      commandLineArgs = "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization --enable-gpu-rasterization --ozone-platform=wayland";
    })
    code-cursor-fhs
    copyq-wrapped
    discord-wrapped
    droidcam
    file-roller
    gedit
    ghostty
    gimp
    gitg
    glycin-loaders # HEIF/AVIF/JXL support for Nautilus & Loupe (GTK4 image loading)
    gnome-browser-connector
    gnome-pomodoro
    gnome-screenshot
    gnome-terminal
    gnome-tweaks
    google-chrome
    gthumb
    keepass
    kdePackages.kdenlive
    frei0r # Video effects (zoom, text, transitions)
    movit # High-quality effects (GPU)
    libheif.out # ships share/thumbnailers/heif.thumbnailer for Nautilus grid thumbnails
    libheif.bin # heif-thumbnailer binary referenced by the .thumbnailer above; keeps it from being GC'd
    rubberband # To adjust audio speed without pitch
    keepassxc
    keymapp
    libreoffice
    lm_sensors
    lmstudio
    menulibre
    minijinja
    nemo-with-extensions
    obsidian
    ocrfeeder
    openvpn
    polari
    proton-vpn
    qalculate-gtk
    stretchly
    sunwait
    telegram-desktop
    tesseract
    vesktop
    vlc
    vscodium
    warp-terminal
    wezterm
    yq
    zed-editor
    zoom-us
  ];

  # Registers the HEIC/HEIF gdk-pixbuf loader so gThumb/Nemo/etc. can open
  # HEIC photos (e.g. straight from an iPhone).
  programs.gdk-pixbuf.modulePackages = [ pkgs.libheif.lib ];

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      droidcam-obs
      obs-backgroundremoval # (optional : green screen or automatic removal)
      obs-pipewire-audio-capture # System audio
      wlrobs # For Wayland (recommended)
    ];
  };

  services.espanso = {
    enable = true;
    package = pkgs.espanso-wayland;
  };
}
