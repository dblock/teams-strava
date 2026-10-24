# Teams Store Listing Copy

Draft copy for the Partner Center app submission form. Not used by the app itself; kept here for reference alongside the screenshots and publisher logo.

## App name

Strata

Use **Strata** for the app name in both Partner Center and the Teams Developer Portal so it matches the manifest's short and full names. Keep Microsoft Teams and Strava references in descriptive copy, not the app name.

## Tagline

Powered by Strava

Use this only as separate attribution, never as part of the app name. The website retains its existing footer logo without a tagline beneath the heading. See the [Microsoft app-name requirements](https://learn.microsoft.com/en-us/microsoftteams/platform/concepts/deploy-and-publish/appsource/prepare/teams-store-validation-guidelines#app-name) and [Strava API Brand Guidelines](https://developers.strava.com/guidelines/).

## Validation update

The updated package is `store/pkg/strata-teams-app.zip` (manifest version 1.0.5). Send it and the updated `store/Strata-testing-instructions.pdf` through the existing Ticket #5811188 email thread. Do not resubmit in Partner Center until Microsoft gives final approval by email. Portal app-name fields must be updated separately; repository changes do not update them.

The package offers team installation and commands in Teams channels only. Personal and group chat installation is not supported.

## Short description (max 100 characters)

Strata connects Strava with Microsoft Teams.

## Full description (max 4000 characters)

Bring your running or cycling club together in Microsoft Teams. Strata helps workplace fitness groups celebrate progress and compare activity totals without manually sharing every workout.

- Share new Strava activities in your connected channel, with time, distance, pace, maps, and weather when available.
- Keep friendly competition in Teams with channel leaderboards and activity statistics.
- Choose activity types, units, maps, and posting limits to fit your group.

**Setup and requirements**

Install Strata in a Teams channel and send @Strata connect. You need an active Strava account and your organization's permission to install the app. Strava sign-in and authorization take place outside Teams.

**Limitations**

Activity sharing and leaderboards require a Teams channel; these workflows are not available in personal or group chats. New activities sync after you connect. Maps require route data, and weather appears only when available. Private activities are excluded by default. Statistics reflect retained activities (30 days by default). Send @Strata disconnect to stop future sharing; existing Teams posts remain.

Strata is currently available at no charge during the beta. Powered by Strava; not officially affiliated with Strava.

[Sign up for Strava](https://www.strava.com/register) | [Get started](https://strata.playplay.io/help.html#get-started) | [Contact support](https://strata.playplay.io/help.html#support) | [Help](https://strata.playplay.io/help.html)

## Support / contact

Daniel Doubrovkine, Vestris LLC - [dblock@vestris.com](mailto:dblock@vestris.com)

## Privacy and terms

- Privacy: https://strata.playplay.io/privacy
- Terms of use: https://strata.playplay.io/terms

## Screenshots

Upload the captioned PNG files in `store/screenshots/` in the order below. Each image is 1366x768 pixels and under 1,024 KB, with dark feature headlines and supporting captions on an original layered blue ribbon background above the existing Teams interface. The palette uses the shoe logo's primary blue, `#314F80`, with lighter tints and overlapping ribbons to reduce empty white space. These are desktop screenshots; mobile screenshots remain a separate recommendation.

| File | Headline | Caption |
| --- | --- | --- |
| `1-marathon.png` | Celebrate every finish | Share activity stats and route maps in your team channel. |
| `2-connect-strava.png` | Connect Strata | Authorize your Strava account in Teams to start sharing activities. |
| `3-activity-post.png` | Keep your team up to speed | See distance, pace, maps, and weather without leaving Teams. |
| `4-settings.png` | Make Strata work for your team | Choose activity types, units, maps, and posting limits. |

### Creating another screenshot

Reuse [screenshot-background.png](screenshot-background.png), the original 1366x768 abstract canvas without captions or app UI. The editable vector source is [screenshot-background.svg](screenshot-background.svg); export it at its intrinsic 1366x768 size when changing the artwork. These are source assets, not additional screenshots to upload to the Store.

The website stretches a public copy of the same artwork, [public/img/screenshot-background.svg](../public/img/screenshot-background.svg), across a fixed viewport-sized background so it does not shift when help topics expand. Keep its artwork in sync when editing the vector source, preserving the public copy's `preserveAspectRatio="none"` setting. The homepage's hero image, [public/img/strata-teams.png](../public/img/strata-teams.png), is the original transparent marathon screenshot from the first submission, without the Store captions or background.

Center the headline at x=683, top=16 using Arial Bold at 34px in `#171717`, and the supporting caption at x=683, top=60 using Arial at 20px in `#292929`. Add a 48x4px `#314F80` divider centered horizontally at top=88. Remove unused margins from the Teams capture, preserve its aspect ratio, and fit the complete window within 1318x648px, horizontally centered at top=104. Do not cover app UI with captions. Export at 1366x768 and keep the PNG under 1,024 KB.

## Testing instructions for reviewers

Reviewers will need a Strava account to test the `connect` flow. Strava
signup is free and instant at https://www.strava.com/register - no need
for us to provide a shared test account/password.

- Teams tenant: fed34e12-9ac2-4aed-ad32-7afb9634f204 (test tenant where
  Strata is installed)

Steps:

1. Create a free Strava account at https://www.strava.com/register (or use
   an existing one).
2. In a Teams channel, `@mention` Strata and send `connect`. Follow the link
   and log in with your Strava account to authorize access.
3. Trigger a new activity so Strata posts it to the channel. Either:
   - On strava.com, use **+ (top right) > Manual Entry** to log an activity
     (type, distance, duration - no GPS file needed), or
   - Upload a GPX file for a version that includes a map: **+ > Upload
     Activity > select file on the left > Choose Files**, pick a sample GPX
     file (e.g. download one from
     https://raw.githubusercontent.com/dblock/teams-strava/master/store/Brighton_Beach.gpx),
     give it a title, then **Save & View**.
   Strata syncs new activities via a Strava webhook within a few seconds.
4. In the channel, try `leaderboard`, `stats`, `set units metric`, and
   `help` to see the other commands.
5. `disconnect` to unlink your Strava account when done, if desired.
