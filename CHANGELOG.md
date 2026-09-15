### Changelog

* 2026/09/14: Reply with a friendly error when the app is installed at personal scope instead of a Teams channel/team - [@dblock](https://github.com/dblock).
* 2026/09/15: Fix `Strava::Errors::Fault: Bad Request` when ensuring the Strava webhook subscription after the callback URL changes (e.g. a new ngrok URL); a stale subscription at the old URL is now deleted before creating the new one - [@dblock](https://github.com/dblock).
* 2026/09/15: Fix activity posts showing up nested/threaded under the message a user typed a command in; Teams appends a `;messageid=...` suffix to `conversation.id` for channel messages, which is now stripped before being stored as a channel/conversation id - [@dblock](https://github.com/dblock).
* 2026/09/15: `connect` now sends the Strava OAuth link via a private 1:1 message instead of posting it in the channel, so it's not visible to other members - [@dblock](https://github.com/dblock).
* Your contribution here.
