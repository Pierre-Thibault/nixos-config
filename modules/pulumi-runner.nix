# Creates the pulumi-runner service user: holds ~/.pulumi/credentials.json
# out of pierre's reach, reachable only through a fixed pulumi wrapper via a
# narrowly scoped sudo rule. See config/pulumi-runner.nix for the shared
# config this module wires up.
{
  config,
  pkgs,
  lib,
  userdata,
  ...
}:

let
  cfg = import ../config/pulumi-runner.nix;

  # Same fix as nixos-anywhere-flake's flake.nix: nixpkgs' `pulumi` lacks the
  # Python language host, and Pulumi refuses to download it separately.
  # Fetch the official release tarball at the exact version nixpkgs pins
  # `pulumi` to, so CLI <-> language host stay protocol-compatible. The
  # sha256 below is pinned to that version's tarball content and does not
  # auto-update — see nixos-anywhere-flake/flake.nix for the update
  # procedure (same fix, kept in sync manually between the two configs).
  pulumiLanguagePython =
    let
      inherit (pkgs.pulumi) version;
    in
    pkgs.stdenv.mkDerivation {
      pname = "pulumi-language-python";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/pulumi/pulumi/releases/download/v${version}/pulumi-v${version}-linux-x64.tar.gz";
        sha256 = "1vpib37pj825vl1v2xp8vzg6fk84vhxsd0c38dljnqh5ypn9d60z";
      };
      sourceRoot = ".";
      installPhase = ''
        mkdir -p $out/bin
        for f in pulumi-language-python pulumi-language-python-exec pulumi-resource-pulumi-python; do
          install -m755 pulumi/$f $out/bin/$f
        done
      '';
    };

  # Merge the vanilla pulumi CLI with the language host above, and bake
  # LD_LIBRARY_PATH into the wrapper itself (needed by Python venvs'
  # manylinux grpc wheel) rather than relying on it surviving the sudo
  # boundary — sudo strips LD_* variables by default specifically because
  # passing them through is a classic library-injection escalation vector.
  pulumiWrapped = pkgs.symlinkJoin {
    name = "pulumi-wrapped";
    paths = [
      pkgs.pulumi
      pulumiLanguagePython
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pulumi \
        --prefix LD_LIBRARY_PATH : ${pkgs.stdenv.cc.cc.lib}/lib
    '';
  };
in
{
  users.groups.${cfg.username} = { };

  users.users.${cfg.username} = {
    isSystemUser = true;
    group = cfg.username;
    home = cfg.home;
    createHome = true;
    shell = "${pkgs.shadow}/bin/nologin";
  };

  environment.systemPackages = [
    pulumiWrapped
    # pulumi-runner's sudo rule sets secure_path to /run/current-system/sw/bin
    # only (see below), so `pulumi install`/`pulumi new` on a project with
    # `toolchain: uv` or `toolchain: poetry` in Pulumi.yaml needs these tools
    # available there too, not just in some project's own devShell.
    pkgs.uv
    pkgs.poetry
  ];

  # env_keep is a global sudo Default (sudoers has no clean per-rule scoping
  # for it), so this is system-wide, not confined to the pulumi-runner rule
  # below. Low risk: it only names benign config values (URLs), never LD_*
  # or anything that could hijack another command's dynamic linking.
  security.sudo.extraConfig = ''
    Defaults env_keep += "${lib.concatStringsSep " " (lib.attrNames cfg.environmentPassthrough)}"
    # NixOS doesn't set secure_path by default, so sudo otherwise passes the
    # caller's own $PATH straight through. Found the hard way: a stale nix
    # store path earlier in an interactive shell's $PATH shadowed the
    # correct pulumi-language-python and got picked up by pulumi-runner's
    # invocation instead of the one baked into the wrapper.
    Defaults secure_path = "/run/current-system/sw/bin:/run/wrappers/bin"
  '';

  security.sudo.extraRules = [
    {
      users = [ userdata.username ];
      runAs = cfg.username;
      commands = [
        {
          # Must be this literal string, not "${pulumiWrapped}/bin/pulumi":
          # sudo matches the invoked command against the sudoers entry as an
          # exact string, without resolving symlinks — so the entry has to
          # be whatever path gets typed at invocation time. This one never
          # changes across generations (only what it points to does), so it
          # stays valid without needing to track the current store hash.
          command = "/run/current-system/sw/bin/pulumi";
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
      ];
    }
  ];

  # Convention directory for Pulumi projects: pulumi-runner needs to write
  # here too (stack init, config set, and pulumi new all create/modify
  # project files -- state alone lives in Pulumi Cloud, but plenty else is
  # local), without a config change per new project. A default ACL on the
  # directory covers future subdirectories automatically; traversal-only
  # (--x) ACLs on the ancestors let pulumi-runner reach it without being
  # able to list or read anything else in pierre's home.
  #
  # Both pulumi-runner's and pierre's ACL entries are set as *default*
  # (inherited), reciprocally: whichever of the two creates a file, the
  # other still gets rwX on it automatically. Without pierre's own default
  # entry here, a file pulumi-runner creates (e.g. a fresh
  # Pulumi.<stack>.yaml) would be owned by pulumi-runner and pierre
  # wouldn't be able to read or edit it directly on disk (git itself
  # doesn't care about ownership, but pierre's editor/shell does).
  system.activationScripts.pulumiRunnerAcls = {
    text = ''
      mkdir -p ${cfg.projectsDirectory}
      chown ${userdata.username}:users ${cfg.projectsDirectory}
      ${pkgs.acl}/bin/setfacl -m u:${cfg.username}:--x /home/${userdata.username}
      ${pkgs.acl}/bin/setfacl -m u:${cfg.username}:--x /home/${userdata.username}/Projets
      ${pkgs.acl}/bin/setfacl -R -m u:${cfg.username}:rwX,u:${userdata.username}:rwX ${cfg.projectsDirectory}
      ${pkgs.acl}/bin/setfacl -R -d -m u:${cfg.username}:rwX,u:${userdata.username}:rwX ${cfg.projectsDirectory}
    '';
    deps = [ ];
  };
}
