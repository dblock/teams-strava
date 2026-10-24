## Debugging

### Locally

You can debug your instance of teams-strava with a built-in `script/console`.

### Teams authentication failures

`Rejected Teams request (401): JWT signing key was not found` means the incoming request reached Strata but failed authentication before command handling. In `teams_rb` 2.0.2, Microsoft's public signing keys were cached indefinitely, so key rotation could stop a long-running bot from responding.

Strata temporarily uses the `dblock/teams_rb` branch `fix/jwks-javascript-parity` from [upstream PR #12](https://github.com/bavmind/teams_rb/pull/12), locked to a specific commit in `Gemfile.lock`. The fix uses `ruby-jwt` for token verification and matches the JavaScript Teams SDK's cache defaults: up to five public keys per JWKS endpoint, each expiring ten minutes after retrieval, with an immediate fetch for an unknown key ID. Expiry and not-before checks allow five minutes of clock tolerance. Key-fetch failures reject authentication with HTTP 401; authentication is not bypassed.

There is intentionally no refresh rate limit or negative cache, matching JavaScript's current configuration, so repeated unknown key IDs can trigger repeated outbound fetches. This differs from the throttled alternative in [PR #10](https://github.com/bavmind/teams_rb/pull/10). Replace the Git dependency with a released version containing the selected fix once available.

See [the incident investigation](https://github.com/dblock/teams-strava/issues/4). Redeploying clears the in-memory cache but is not a lasting fix; reinstalling the Teams app or rotating Strata's client secret does not address stale Microsoft public keys.

### Silence Mongoid Logger

If Mongoid logging is annoying you.

```ruby
Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO
```
