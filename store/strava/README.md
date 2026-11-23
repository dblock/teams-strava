# Strava Developer Program Request

Strava limits how many athletes can connect to an API application. Strata is on the Standard tier, which allows 10 connected athletes without review. To connect more athletes, submit the [Strava API Program Submission Form](https://share.hsforms.com/1VXSwPUYqSH6IxK0y51FjHwcnkd8). The form says Strava reviews only applications that have reached the 10-athlete limit and denies the rest, so submit once Strata has 10 connected athletes. Check the count at [Strava API settings](https://www.strava.com/settings/api). Expanded access is not guaranteed, and Strava may approve a lower capacity than requested.

## Before Submitting

- Strata follows the [Strava brand guidelines](https://developers.strava.com/guidelines/): the official Connect with Strava button, "View on Strava" links back to activities, and "Powered by Strava" attribution on the website.
- Strata deletes an athlete's tokens, stored activities, and profile when the athlete revokes access on Strava, as the [Strava API agreement](https://www.strava.com/legal/api) requires.
- Review the API agreement, API policy, and brand guidelines again, because the form asks you to confirm each one.

## Form Fields

| Field | Answer |
| --- | --- |
| First name, Last name | The submitter's name. |
| Email Address | The submitter's email. Strava replies from developers@strava.com, so make sure that address isn't marked as spam. |
| Company Name | Vestris LLC |
| API Application Name | Strata |
| Strava Client ID | 279799 |
| Additional Apps | The client ID of any separate development or staging Strava application, or empty if there is none. Strava requires a subscription for each application. |
| Number of Currently Authenticated Users | The connected athlete count from Strava API settings, at least 10. |
| Number of Intended Users | A rough estimate, such as 500. |
| Application Description | See [Application Description](#application-description). |
| Support URL | https://strata.playplay.io/help.html#support |
| TOS Compliance, API Policy Compliance, Brand Guidelines Review | Check each box after reviewing the linked documents. |
| App Images | All six files in [screenshots](screenshots). |

## Application Description

Strata (https://strata.playplay.io) is a Microsoft Teams app for workplace running, cycling, and fitness groups, and is in review for the Microsoft Teams Store. Each athlete connects their own Strava account with the official Connect with Strava button (OAuth, activity:read_all). Strata then posts that athlete's new activities to the Teams channel where they connected, with distance, time, pace, elevation, a map, and weather, and shows channel leaderboards and stats.

Strata reads only the connecting athlete's own activities, only to share them with the coworkers in the channel that athlete chose. Private activities are not posted by default, and followers-only activities can be excluded. Strava data is never sold, shared with third parties, or used for advertising or AI training. Each post links back with "View on Strava", and Strata is described as "Powered by Strava".

Stored activities are deleted after the team's retention period, 30 days by default and at most 6 months. "@Strata disconnect" revokes the token. When an athlete revokes access on Strava, the deauthorization webhook deletes their tokens, stored activities, and athlete profile. Strata uses a single webhook subscription for activity create, update, and delete events and for deauthorization, and does not poll.

The app is open source (https://github.com/dblock/teams-strava). The same author runs Slava, the Strava integration for Slack, built on the same code.

## Screenshots

The form asks for screenshots of every place Strata shows Strava data. Names, the activity title, the test team's name, and the browser profile photo are anonymized.

| File | Shows |
| --- | --- |
| [1-connect-with-strava.png](screenshots/1-connect-with-strava.png) | The Connect with Strava button after `@Strata connect`. |
| [2-activity-post.png](screenshots/2-activity-post.png) | An activity post on Teams desktop, with a map and "View on Strava". |
| [3-activity-post-mobile.png](screenshots/3-activity-post-mobile.png) | The same post on Teams mobile. |
| [4-leaderboard.png](screenshots/4-leaderboard.png) | `@Strata leaderboard distance`. |
| [5-stats.png](screenshots/5-stats.png) | `@Strata stats`. |
| [6-website.png](screenshots/6-website.png) | The website with the Powered by Strava logo. |
