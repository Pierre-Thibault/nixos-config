{
  pkgs,
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
    audacity
    brave
    copyq-wrapped
    code-cursor-fhs
    nemo-with-extensions
    file-roller
    gedit
    gimp
    gitg
    gnome-browser-connector
    gnome-pomodoro
    gnome-screenshot
    gnome-terminal
    gnome-tweaks
    google-chrome
    ghostty
    gthumb
    keepass
    keepassxc
    keymapp
    libreoffice
    lm_sensors
    menulibre
    obs-studio
    obsidian
    ocrfeeder
    openvpn
    polari
    protonvpn-gui
    qalculate-gtk
    stretchly
    telegram-desktop
    tesseract
    vesktop
    vlc
    vscodium
    warp-terminal
    wezterm
    zed-editor
  ];
}
