Strata
======

[![Tests](https://github.com/dblock/teams-strava/actions/workflows/test.yml/badge.svg)](https://github.com/dblock/teams-strava/actions/workflows/test.yml)
[![Coverage](https://img.shields.io/badge/coverage-87.95%25-brightgreen)](https://github.com/dblock/teams-strava)

Integrate Strava into Microsoft Teams. Hosted at [strata.playplay.io](https://strata.playplay.io/).

## Install

Sideload or publish the [Teams app package](manifest) into your team, then @mention `Strata` to get started, e.g. `@Strata help`.

## Website caching

Local template assets use `asset_path` content hashes, including favicon, social and checkout images. The generated `styles.css.erb` versions its nested ribbon artwork and revalidates with `Cache-Control: private, no-cache`; template timestamps cannot validate changes to nested assets. Static ETags and timestamps retain their defaults. Old `?v=` URLs serve current files, not archived versions; do not apply immutable or long-lived caching.

### Copyright & License

Copyright [Daniel Doubrovkine, Vestris LLC](https://www.vestris.com), 2023-2026

[MIT License](LICENSE)
