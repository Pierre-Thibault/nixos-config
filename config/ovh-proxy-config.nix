# Non-secret config for the OVH signing proxy (modules/ovh-proxy.nix).
# Shares api-proxy's port/bindAddr (see config/cloud-proxy-config.nix) --
# Caddy differentiates upstreams by hostname, not port.
{
  hostname = "ovh.proxy";
  # Real OVH endpoint the signature is computed against and the request is
  # ultimately forwarded to. Canada account -> ca.api.ovh.com (region-locked:
  # credentials from one OVH region don't authenticate against another).
  upstreamHost = "ca.api.ovh.com";
  sessionVars = {
    OVH_ENDPOINT = "http://ovh.proxy:4140/1.0";
  };
}
