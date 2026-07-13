# Python packages requested by Claude Code for scripting tasks (OKF frontmatter, catalog generation, etc.)
{
  pkgs,
  ...
}:

let
  cfg = import ../ai-config.nix;
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pyyaml            # YAML frontmatter parsing
      python-frontmatter # Markdown + YAML frontmatter parsing
      rich              # Terminal output formatting
    ]
  );
in
{
  users.users.${cfg.username}.packages = [
    pythonEnv
  ];
}
