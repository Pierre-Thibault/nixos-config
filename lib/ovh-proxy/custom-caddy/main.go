// Custom Caddy build including the ovhsign module (see ../ovhsign), built
// the way xcaddy would, but hand-written so it's a normal, sandboxed,
// reproducible `buildGoModule` derivation instead of xcaddy's own
// network-fetching build step.
package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	// Standard modules a normal `caddy` binary ships with.
	_ "github.com/caddyserver/caddy/v2/modules/standard"

	// Our OVH request-signing middleware.
	_ "git.pierrethibault.dev/nixos-config/ovhsign"
)

func main() {
	caddycmd.Main()
}
