{
  pkgs,
  ...
}:

let
  userdata = import ../userdata.nix;
in
{
  users.users.${userdata.username}.packages = with pkgs; [
    # General dev tools that I want available all the times
    lsp-ai
    marksman
    taplo
    typescript-language-server
    vscode-langservers-extracted # Gives  vscode-html-language-server vscode-css-language-server vscode-json-language-server vscode-eslint-language-server
    yaml-language-server
  ];
}
