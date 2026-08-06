# Configuration for the pulumi-runner service user (see modules/pulumi-runner.nix,
# not yet written). pulumi-runner holds ~/.pulumi/credentials.json out of
# pierre's reach; pierre can only invoke a fixed pulumi wrapper as that user
# via a narrowly scoped sudo rule.
let
  userdata = import ./userdata.nix;

  # Top-level so it's a single, easy attribute to pull from outside Nix too
  # (e.g. `nix eval --raw -f ~/nixos-config/config/pulumi-runner.nix DIGITALOCEAN_API_URL`
  # from ~/.zshrc), instead of reaching into a nested attrset.
  DIGITALOCEAN_API_URL = "http://digitalocean.proxy:4140";
in
{
  inherit DIGITALOCEAN_API_URL;

  username = "pulumi-runner";
  home = "/var/lib/pulumi-runner";

  # Convention directory for Pulumi projects (see nixos-anywhere-flake/infra,
  # symlinked here). Gets a default ACL granting pulumi-runner read+traverse,
  # so new projects created underneath need no config change to be reachable.
  projectsDirectory = "/home/${userdata.username}/Projets/pulumi";

  # Variables allowed through the sudo boundary (env_keep) when pierre runs
  # the pulumi wrapper as pulumi-runner.
  environmentPassthrough = {
    inherit DIGITALOCEAN_API_URL;
  };
}
