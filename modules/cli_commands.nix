{
  pkgs,
  ...
}:

let
  userdata = import ../userdata.nix;
in
# unstable = import <nixos-unstable> {
#   config = {
#     allowUnfree = true;
#   };
# };
{
  users.users.${userdata.username}.packages = with pkgs; [
    bat
    dconf
    direnv
    fanctl
    file
    fzf
    gcc
    git
    gitleaks
    gnupg
    gnumake
    helix
    lsb-release
    lsd
    lsp-ai
    marksman
    mc
    nap
    neofetch
    nixd
    nixfmt-rfc-style
    nushell
    openjdk17-bootstrap
    ripgrep
    ripgrep-all
    stow
    tree
    unzip
    vim
    wget
    wl-clipboard
    yazi
    yt-dlp
    zellij
    zoxide
    zsh
  ];
}
