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
    droidcam
    file-roller
    gedit
    ghostty
    gimp
    gitg
    gnome-browser-connector
    gnome-pomodoro
    gnome-screenshot
    gnome-terminal
    gnome-tweaks
    go-grip
    google-chrome
    gthumb
    keepass
    kdePackages.kdenlive
    frei0r # Video effects (zoom, text, transitions)
    movit # High-quality effects (GPU)
    rubberband # To adjust audio speed without pitch    keepass
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
    pika-backup
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

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      droidcam-obs
      obs-backgroundremoval # (optional : green screen or automatic removal)
      obs-pipewire-audio-capture # System audio
      wlrobs # For Wayland (recommended)
    ];
  };
}
