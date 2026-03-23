{
  pkgs,
  ...
}:

let
  userdata = import ../userdata.nix;
  username = userdata.username;
  homeDir = "/home/${username}";

  gtk3-slate-css = pkgs.writeText "gtk3-slate.css" ''
    /* Slate accent color override */
    @define-color accent_bg_color #6e808c;
    @define-color accent_fg_color #ffffff;
    @define-color accent_color #5c6c76;
    @define-color theme_selected_bg_color #6e808c;
    @define-color theme_selected_fg_color #ffffff;

    *:selected,
    *:selected:focus,
    selection,
    textview text selection,
    entry selection,
    spinbutton selection,
    modelbutton:selected,
    menu menuitem:hover,
    menubar > menuitem:hover,
    .context-menu menuitem:hover {
        background-color: #6e808c;
        color: #ffffff;
    }
  '';

  waterfox-user-js = pkgs.writeText "waterfox-user.js" ''
    // Force native GTK theming for accent colors
    user_pref("widget.non-native-theme.enabled", false);

    // Enable userChrome.css loading
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
  '';

  waterfox-userchrome-css = pkgs.writeText "waterfox-userChrome.css" ''
    /* Slate accent color for Waterfox UI */
    :root {
        --lwt-accent-color: #6e808c !important;
        --toolbar-field-focus-border-color: #6e808c !important;
    }

    *::-moz-selection,
    *::selection {
        background-color: #6e808c !important;
        color: #ffffff !important;
    }

    menuitem[_moz-menuactive="true"],
    menu[_moz-menuactive="true"] {
        background-color: #6e808c !important;
        color: #ffffff !important;
    }
  '';
in
{
  # Run setup script on activation
  system.activationScripts.gtk-slate-accent = {
    text = ''
      # GTK3 config for native apps
      mkdir -p "${homeDir}/.config/gtk-3.0"
      cp -f ${gtk3-slate-css} "${homeDir}/.config/gtk-3.0/gtk.css"
      chown ${username}:users "${homeDir}/.config/gtk-3.0/gtk.css"

      # GTK3 config for Flatpak Waterfox
      mkdir -p "${homeDir}/.var/app/net.waterfox.waterfox/config/gtk-3.0"
      cp -f ${gtk3-slate-css} "${homeDir}/.var/app/net.waterfox.waterfox/config/gtk-3.0/gtk.css"
      chown -R ${username}:users "${homeDir}/.var/app/net.waterfox.waterfox/config"

      # Waterfox profile setup (userChrome.css and user.js)
      WATERFOX_DIR="${homeDir}/.var/app/net.waterfox.waterfox/.waterfox"
      if [ -d "$WATERFOX_DIR" ]; then
        for profile in "$WATERFOX_DIR"/*.default*; do
          if [ -d "$profile" ]; then
            mkdir -p "$profile/chrome"
            cp -f ${waterfox-userchrome-css} "$profile/chrome/userChrome.css"
            cp -f ${waterfox-user-js} "$profile/user.js"
            chown -R ${username}:users "$profile/chrome" "$profile/user.js"
          fi
        done
      fi
    '';
    deps = [ ];
  };
}
