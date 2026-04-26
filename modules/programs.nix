{
  pkgs,
  unstable,
  ...
}:

let
  userdata = import ../userdata.nix;

  # Wrapper pour CopyQ qui ignore le thème Qt global
  copyq-wrapped = pkgs.symlinkJoin {
    name = "copyq-wrapped";
    paths = [ pkgs.copyq ];
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
    brave
    (brave.override {
      commandLineArgs = "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization --enable-gpu-rasterization --ozone-platform=wayland";
    })
    code-cursor-fhs
    copyq-wrapped
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
    google-chrome
    gthumb
    keepass
    keepassxc
    keymapp
    libreoffice
    lm_sensors
    lmstudio
    menulibre
    minijinja
    nemo-with-extensions
    obs-studio
    obsidian
    ocrfeeder
    openvpn
    polari
    protonvpn-gui
    qalculate-gtk
    stretchly
    sunwait
    telegram-desktop
    tesseract
    unstable.opencode-desktop
    vesktop
    vlc
    vscodium
    warp-terminal
    wezterm
    yq
    zed-editor
    zoom-us
  ];
}
