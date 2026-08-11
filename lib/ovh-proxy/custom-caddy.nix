# Caddy 2.11.4 (matching nixpkgs' pkgs.caddy) plus the ovhsign module
# (./ovhsign), built by hand the way xcaddy would, but as a normal
# sandboxed buildGoModule derivation instead of xcaddy's network-fetching
# build step. See ovhsign/ovhsign.go for what the module actually does.
{ pkgs, lib }:

pkgs.buildGoModule {
  pname = "custom-caddy";
  version = "2.11.4-ovhsign";

  src = ./.;
  modRoot = "custom-caddy";

  vendorHash = "sha256-z1GwEHI5LakqHfZ6ymXBTnkVqVX4lqW7T+ErBTl4kSE=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "Caddy 2.11.4 with an added http.handlers.ovh_sign module for OVH API request signing";
    mainProgram = "custom-caddy";
  };
}
