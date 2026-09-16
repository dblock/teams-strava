### Changelog

* 2026/09/14: Reply with a friendly error when the app is installed at personal scope instead of a Teams channel/team - [@dblock](https://github.com/dblock).
* 2026/09/15: Fix `Strava::Errors::Fault: Bad Request` when ensuring the Strava webhook subscription after the callback URL changes (e.g. a new ngrok URL); a stale subscription at the old URL is now deleted before creating the new one - [@dblock](https://github.com/dblock).
* 2026/09/15: Fix activity posts showing up nested/threaded under the message a user typed a command in; Teams appends a `;messageid=...` suffix to `conversation.id` for channel messages, which is now stripped before being stored as a channel/conversation id - [@dblock](https://github.com/dblock).
* 2026/09/15: Fix `help` rendering as a single run-on paragraph with a stray literal ` ``` `; replaced the Discord-style fenced ASCII table with Teams-friendly markdown headers and bullet lists - [@dblock](https://github.com/dblock).
* 2026/09/16: Document a separate production Azure Bot/Entra app registration setup in DEV.md (own `CLIENT_ID`/`CLIENT_SECRET`, isolated subscription for billing) and fix the outdated `az bot create --messaging-endpoint` flag to `--endpoint` - [@dblock](https://github.com/dblock).
* 2026/09/16: Link directly to Slack/Discord Strava bot sites in the homepage footer instead of their GitHub repos - [@dblock](https://github.com/dblock).
* 2026/09/16: Increase subscription price from $19.99/yr to $24.99/yr - [@dblock](https://github.com/dblock).
* 2026/09/16: Add `script/verify_production.rb`, a production sanity check for env vars, Bot Framework auth, Stripe plan/price, MongoDB and Strava auth - [@dblock](https://github.com/dblock).
* 2026/09/16: Point the Teams app manifest at the production bot registration and bump manifest version to 1.0.0, ready for Teams Store submission - [@dblock](https://github.com/dblock).
* 2026/09/16: Make Strata free while in beta: disable trial/subscription expiration enforcement, and fix a broken app download link on the homepage by serving the Teams app package (manifest + icons) on demand from `/strata-teams-app.zip`, cached like map images - [@dblock](https://github.com/dblock).
* 2026/09/16: Put each sentence of the beta note on its own line - [@dblock](https://github.com/dblock).
* 2026/09/16: Fix `NameError: uninitialized constant TeamsStrava::TeamsAppPackage::Zip` in production when downloading the Teams app package; `rubyzip` was only available transitively via a test-only gem, now an explicit runtime dependency - [@dblock](https://github.com/dblock).
* 2026/09/16: Render the Strava activity map at full width instead of a small fixed size in Teams cards - [@dblock](https://github.com/dblock).
* Your contribution here.
