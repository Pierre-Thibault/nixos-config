// Package ovhsign implements a Caddy HTTP middleware that signs outgoing
// requests for the OVH API. OVH's auth isn't a static bearer token like
// DigitalOcean's -- every request needs a fresh X-Ovh-Timestamp and an
// X-Ovh-Signature computed over the method, full upstream URL, body, and
// timestamp using the real application secret and consumer key. That can't
// be expressed as a static header_up value, hence this module: it runs
// before reverse_proxy, signs the request in place, and the real secret
// never leaves the Caddy process.
package ovhsign

import (
	"bytes"
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/httpcaddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
)

func init() {
	caddy.RegisterModule(OVHSign{})
	httpcaddyfile.RegisterHandlerDirective("ovh_sign", parseCaddyfile)
}

// OVHSign signs the request in place, then hands off to the next handler
// (normally reverse_proxy) to actually forward it.
type OVHSign struct {
	// Names of environment variables holding the real credentials -- not
	// the credentials themselves, so they never end up in the Caddyfile or
	// Caddy's JSON config dump.
	ApplicationKeyEnv    string `json:"application_key_env,omitempty"`
	ApplicationSecretEnv string `json:"application_secret_env,omitempty"`
	ConsumerKeyEnv       string `json:"consumer_key_env,omitempty"`
	// Real upstream host the signature must be computed against (e.g.
	// eu.api.ovh.com), independent of whatever local hostname this site
	// block listens on.
	UpstreamHost string `json:"upstream_host,omitempty"`
}

func (OVHSign) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "http.handlers.ovh_sign",
		New: func() caddy.Module { return new(OVHSign) },
	}
}

func (m *OVHSign) Validate() error {
	if m.ApplicationKeyEnv == "" || m.ApplicationSecretEnv == "" || m.ConsumerKeyEnv == "" || m.UpstreamHost == "" {
		return fmt.Errorf("ovh_sign: application_key_env, application_secret_env, consumer_key_env, and upstream_host are all required")
	}
	return nil
}

func (m *OVHSign) ServeHTTP(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler) error {
	appKey := os.Getenv(m.ApplicationKeyEnv)
	appSecret := os.Getenv(m.ApplicationSecretEnv)
	consumerKey := os.Getenv(m.ConsumerKeyEnv)

	var body []byte
	if r.Body != nil {
		var err error
		body, err = io.ReadAll(r.Body)
		if err != nil {
			return err
		}
		r.Body = io.NopCloser(bytes.NewReader(body))
	}

	timestamp := fmt.Sprintf("%d", time.Now().Unix())
	url := "https://" + m.UpstreamHost + r.URL.RequestURI()

	toSign := appSecret + "+" + consumerKey + "+" + r.Method + "+" + url + "+" + string(body) + "+" + timestamp
	sum := sha1.Sum([]byte(toSign))
	signature := "$1$" + hex.EncodeToString(sum[:])

	r.Header.Set("X-Ovh-Application", appKey)
	r.Header.Set("X-Ovh-Consumer", consumerKey)
	r.Header.Set("X-Ovh-Timestamp", timestamp)
	r.Header.Set("X-Ovh-Signature", signature)

	return next.ServeHTTP(w, r)
}

func parseCaddyfile(h httpcaddyfile.Helper) (caddyhttp.MiddlewareHandler, error) {
	m := new(OVHSign)
	for h.Next() {
		for h.NextBlock(0) {
			switch h.Val() {
			case "application_key_env":
				if !h.NextArg() {
					return nil, h.ArgErr()
				}
				m.ApplicationKeyEnv = h.Val()
			case "application_secret_env":
				if !h.NextArg() {
					return nil, h.ArgErr()
				}
				m.ApplicationSecretEnv = h.Val()
			case "consumer_key_env":
				if !h.NextArg() {
					return nil, h.ArgErr()
				}
				m.ConsumerKeyEnv = h.Val()
			case "upstream_host":
				if !h.NextArg() {
					return nil, h.ArgErr()
				}
				m.UpstreamHost = h.Val()
			default:
				return nil, h.Errf("unrecognized ovh_sign option '%s'", h.Val())
			}
		}
	}
	return m, nil
}

var (
	_ caddy.Module                = (*OVHSign)(nil)
	_ caddy.Validator              = (*OVHSign)(nil)
	_ caddyhttp.MiddlewareHandler = (*OVHSign)(nil)
)
