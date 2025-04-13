# This the Neovim configuration
#
{ ... }:

{
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        startPlugins = [
          "catppuccin"
        ];

        languages = {
          enableLSP = true;
          enableTreesitter = true;

          css.enable = true;
          gleam.enable = true;
          go.enable = true;
          html.enable = true;
          lua.enable = true;
          markdown.enable = true;
          nix.enable = true;
          python.enable = true;
          rust.enable = true;
          sql.enable = true;
          ts.enable = true; # This does Javascript too
          yaml.enable = true;
        };

        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
          transparent = true;
        };
      };
    };
  };
}
