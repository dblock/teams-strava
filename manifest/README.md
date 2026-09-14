# Teams App Manifest

This directory contains the [Teams app manifest](https://learn.microsoft.com/en-us/microsoftteams/platform/resources/schema/manifest-schema) for Strata. Commands are declared statically in this manifest and only take effect after the app package is uploaded/published.

## Before publishing

1. Register an Azure Bot resource (or Microsoft 365 Agents Toolkit equivalent) and note its Bot ID (Microsoft App ID); this is also `CLIENT_ID`.
2. Replace both `00000000-0000-0000-0000-000000000000` placeholders in `manifest.json`:
   - `id` — a new GUID identifying this Teams app.
   - `bots[0].botId` — the Bot ID from step 1.
3. Add `color.png` (192x192) and `outline.png` (32x32, transparent) icons to this directory.
4. Update `developer`, `validDomains`, `privacyUrl` and `termsOfUseUrl` if the service is hosted elsewhere.
5. Set the bot's messaging endpoint to `https://<host>/api/messages` (see `TeamsStrava::Bot`).

## Packaging

Zip `manifest.json`, `color.png` and `outline.png` together (flat, no subfolder) to produce the app package, then upload it via Teams Admin Center, App Studio/Developer Portal, or `teams_rb`'s equivalent tooling.
