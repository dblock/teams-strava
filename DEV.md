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

On macOS, the CLI tools referenced below can be installed with Homebrew.

```
brew install azure-cli ngrok node
npm i -g @pnp/cli-microsoft365
```

### Microsoft Teams/Bot Framework Platform

Get familiar with the Bot Framework and Teams platform [here](https://learn.microsoft.com/en-us/microsoftteams/platform/bots/what-are-bots).

### Azure Bot Registration

Register a bot resource in Azure (via the [Azure Bot](https://learn.microsoft.com/en-us/azure/bot-service/abs-quickstart) service, the Azure CLI, or the [Microsoft 365 Agents Toolkit](https://learn.microsoft.com/en-us/microsoftteams/platform/toolkit/teams-toolkit-fundamentals)). This gives you:

* An application (client) ID, `CLIENT_ID`.
* A client secret, `CLIENT_SECRET`.
* A tenant ID, `TENANT_ID` (use your Microsoft 365 developer tenant while testing).

Using the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/):

```
# log in; if your tenant is a Microsoft 365 developer tenant with no Azure
# subscription attached, add --allow-no-subscriptions (Entra ID app/service
# principal commands work fine without one; az bot create below needs a
# real, billable subscription, which may mean a different login/tenant)
az login --tenant "<TENANT_ID>" --allow-no-subscriptions
az account set --subscription "<subscription-name-or-id>"

# create a resource group, if you don't already have one
az group create --name strata-dev --location eastus

# create the Entra ID app registration (this is CLIENT_ID)
CLIENT_ID=$(az ad app create --display-name strata-dev --query appId -o tsv)
echo "CLIENT_ID=$CLIENT_ID"

# create a client secret (this is CLIENT_SECRET, shown only once)
CLIENT_SECRET=$(az ad app credential reset --id "$CLIENT_ID" --append \
  --display-name "strata-dev-secret" --years 1 --query password -o tsv)
echo "CLIENT_SECRET=$CLIENT_SECRET"

# note your tenant ID (this is TENANT_ID)
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "TENANT_ID=$TENANT_ID"

# create the Azure Bot resource (messaging endpoint can be a placeholder for now)
az bot create \
  --resource-group strata-dev \
  --name strata-dev \
  --app-type SingleTenant \
  --appid "$CLIENT_ID" \
  --tenant-id "$TENANT_ID" \
  --messaging-endpoint "https://example.com/api/messages"

# enable the Microsoft Teams channel
az bot msteams create --resource-group strata-dev --name strata-dev
```

### Teams App Manifest

Fill out [manifest/manifest.json](manifest/manifest.json), see [manifest/README.md](manifest/README.md). Package it into a zip:

```
cd manifest
zip -j /tmp/strata-teams-app.zip manifest.json color.png outline.png
cd ..
```

Once the app has been published (or sideloaded with a real `id` in the manifest), set `TEAMS_APP_ID` to that GUID so the homepage's "Add to Microsoft Teams" button links directly to the Teams install deep link (`https://teams.microsoft.com/l/app/<TEAMS_APP_ID>`) instead of a manifest download. `TEAMS_APP_INSTALL_URL` can be set instead to override this link entirely (e.g. to a Teams Store listing URL).

### Keys

Create a `.env` file from [.env.sample](.env.sample). Fill the Strava and Teams keys at a minimum, including the `CLIENT_ID`, `CLIENT_SECRET` and `TENANT_ID` obtained above.

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

Set the bot's _Messaging endpoint_ to `https://....ngrok-free.app/api/messages`.

Via the Azure Portal, edit the Azure Bot resource's _Configuration_ blade, or via the Azure CLI:

```
az bot update \
  --resource-group strata-dev \
  --name strata-dev \
  --endpoint "https://....ngrok-free.app/api/messages"
```

### Installing the App

Sideload the app package (built above) into a team via the Teams client: **Apps** > **Manage your apps** > **Upload an app** > **Upload a custom app**, or from within a team/channel's **Apps** tab.

Alternatively, install/update it from the command line with [CLI for Microsoft 365](https://pnp.github.io/cli-microsoft365/), which wraps the Microsoft Graph Teams app APIs and skips the manual upload/remove/re-add UI flow.

#### CLI for Microsoft 365 Login

Recent versions of the CLI no longer ship with a shared built-in Entra app, so `m365 login` needs its own app registration (this is separate from the bot's `CLIENT_ID`, which is a confidential/single-tenant identity and isn't set up for CLI/device-code login). Register it in the **same tenant** where your team/app lives (`TENANT_ID` above) — logging in with an app from a different tenant will authenticate fine but won't see that tenant's teams or app catalog.

```
# register an app for the CLI itself, in the same tenant as TENANT_ID
CLI_APP_ID=$(az ad app create --display-name "m365-cli" --query appId -o tsv)
echo "CLI_APP_ID=$CLI_APP_ID"

# allow device-code/public-client login
az ad app update --id "$CLI_APP_ID" --is-fallback-public-client true

# a service principal is required before permissions can be granted
az ad sp create --id "$CLI_APP_ID"

# add the Graph delegated permissions the CLI needs to manage Teams apps:
# AppCatalog.ReadWrite.All, TeamsAppInstallation.ReadWriteForTeam,
# TeamworkAppSettings.ReadWrite.All, Team.ReadBasic.All
GRAPH_API=00000003-0000-0000-c000-000000000000
az ad app permission add --id "$CLI_APP_ID" --api "$GRAPH_API" --api-permissions \
  1ca167d5-1655-44a1-8adf-1414072e1ef9=Scope \
  2e25a044-2580-450d-8859-42eeb6e996c0=Scope \
  87c556f0-2bd9-4eed-bd74-5dd8af6eaf7e=Scope \
  485be79e-c497-4b35-9400-0e3fa7f2a5d4=Scope

# grant/consent to those permissions (requires a Global/Cloud App Admin the
# first time; re-run `m365 login` after this to pick up the new consent)
az ad app permission grant --id "$CLI_APP_ID" --api "$GRAPH_API" --scope \
  "AppCatalog.ReadWrite.All TeamsAppInstallation.ReadWriteForTeam TeamworkAppSettings.ReadWrite.All Team.ReadBasic.All"

# log in using this app
m365 login --appId "$CLI_APP_ID" --tenant "$TENANT_ID"
```

If you change permissions after already logging in, run `m365 logout` then `m365 login` again to force a new token with the updated scopes. Alternatively, skip all of the above and run `m365 setup`, which automates this registration for you interactively.

#### Publish and Install

```
# publish the app to your tenant's app catalog (first time only)
m365 teams app publish --filePath /tmp/strata-teams-app.zip

# after any manifest change, bump manifest.json's "version" (e.g. 0.1.0 ->
# 0.1.1) first, otherwise this fails with "manifest version exists":
m365 teams app update --id <appCatalogId> --filePath /tmp/strata-teams-app.zip

# find your team ID (--joined lists only teams you belong to and needs less
# privilege than the unflagged form, which lists every team in the tenant)
m365 teams team list --joined

# install the app into a team
m365 teams app install --appId <appCatalogId> --teamId <teamId>

# or install it for yourself only (personal scope)
m365 entra user get --userName you@yourtenant.onmicrosoft.com
m365 teams user app install --userId <yourUserId> --appId <appCatalogId>

# force a refresh (e.g. after manifest changes that don't bump the version)
m365 teams app uninstall --appId <appCatalogId> --teamId <teamId>
m365 teams app install --appId <appCatalogId> --teamId <teamId>
```

`<appCatalogId>` is printed by `teams app publish`/returned by `m365 teams app list`; it's different from the manifest's own `id`. Some of these operations require a Teams Service Admin or Global Admin account to consent to the underlying `TeamsAppInstallation.*` permissions the first time.

Once installed, @mention the bot, e.g. `@Strata help`.

