# Teams Store Listing Copy

Draft copy for the Partner Center app submission form. Not used by the app
itself; kept here for reference alongside the screenshots and publisher logo.

## Short description (max 100 characters)

Strata connects Strava with Microsoft Teams.

## Full description (max 4000 characters)

Strata posts your team's Strava activities to a Microsoft Teams channel,
tracks leaderboards and stats, and lets everyone connect their own Strava
account.

Every new activity is automatically reposted into the channel with:

- Moving and elapsed time, distance, pace, speed and elevation
- A map of the route
- Weather at the time of the activity

Perfect for a running or cycling club inside your Teams organization.

Commands:

- `connect` - connect your Strava account
- `disconnect` - disconnect your Strava account
- `set` - change settings, e.g. "set units metric"
- `leaderboard` - display a team leaderboard, e.g. "leaderboard distance this month"
- `stats` - display team stats for the past 30 days
- `subscription` - show subscription info and a link to update the payment method
- `help` - get a helpful message listing all commands

Strata is not officially affiliated with Strava.

## Support / contact

Daniel Doubrovkine, Vestris LLC - dblock@vestris.com

## Privacy and terms

- Privacy: https://strata.playplay.io/privacy
- Terms of use: https://strata.playplay.io/terms

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
