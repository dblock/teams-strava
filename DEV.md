## Development Environment

### Prerequisites

Ensure that you can build the project and run tests. You will need these.

- [MongoDB](https://docs.mongodb.com/manual/installation/)
- [Firefox](https://www.mozilla.org/firefox/new/)
- [Geckodriver](https://github.com/mozilla/geckodriver), download, `tar vfxz` and move to `/usr/local/bin`
- Ruby 4.0.5

```
bundle install
bundle exec rake
```

### Microsoft Teams/Bot Framework Platform

Get familiar with the Bot Framework and Teams platform [here](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/what-are-bots).

### Azure Bot Registration

Register a bot resource in Azure (via the [Azure Bot](https://learn.microsoft.com/en-us/azure/bot-service/abs-quickstart) service or the [Microsoft 365 Agents Toolkit](https://learn.microsoft.com/en-us/microsoftteams/platform/toolkit/teams-toolkit-fundamentals)). This gives you:

* An application (client) ID, `CLIENT_ID`.
* A client secret, `CLIENT_SECRET`.
* A tenant ID, `TENANT_ID` (use your Microsoft 365 developer tenant while testing).

### Teams App Manifest

Fill out and package [manifest/manifest.json](manifest/manifest.json), see [manifest/README.md](manifest/README.md), and upload/sideload the resulting app package into a team.

Once the app has been published (or sideloaded with a real `id` in the manifest), set `TEAMS_APP_ID` to that GUID so the homepage's "Add to Microsoft Teams" button links directly to the Teams install deep link (`https://teams.microsoft.com/l/app/<TEAMS_APP_ID>`) instead of a manifest download. `TEAMS_APP_INSTALL_URL` can be set instead to override this link entirely (e.g. to a Teams Store listing URL).

### Keys

Create a `.env` file from [.env.sample](.env.sample). Fill the Strava and Teams keys at a minimum.

### Start the Bot

```
$ foreman start

08:54:07 web.1  | started with pid 32503
08:54:08 web.1  | I, [2017-08-04T08:54:08.138999 #32503]  INFO -- : listening on addr=0.0.0.0:5000 fd=11
```

Navigate to [localhost:5000](http://localhost:5000).

### NGrok

Use ngrok to run an externally visible instance.

```
$ ngrok http 5000
```

Note the URL.

### Set URL in .env

Add the ngrok URL to `.env`.

```
URL=https://6979-173-68-96-34.ngrok-free.app
```

Ctrl+C and restart the bot with `foreman start`.

### Messaging Endpoint

Set the bot's _Messaging endpoint_ in the Azure Bot resource to `https://....ngrok-free.app/api/messages`. Then install the app package (see above) into a team and @mention the bot, e.g. `@Strata help`.

