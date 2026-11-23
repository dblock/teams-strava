# AI Agent Instructions

## Starting Work

Before creating a new branch, always sync and clean up:

```
git checkout master
git pull
git branch --merged master | grep -v '^\* \|^  master$' | xargs -r git branch -d
```

## After Making Code Changes

Always run the following commands before committing:

1. **Fix lint**: `bundle exec rubocop -a`
2. **Update rubocop todo**: `bundle exec rubocop --auto-gen-config`
3. **Run tests**: `bundle exec rspec`

## Changelog

Update [CHANGELOG.md](CHANGELOG.md) for any user-facing change. Add a line at the top under `### Changelog` in the format:

```
* YYYY/MM/DD: Description of change - [@dblock](https://github.com/dblock), [@Copilot](https://github.com/apps/copilot-swe-agent).
```

## Teams Store Policy

- Teams messages (bot replies, cards, and proactive posts) render on Teams mobile, so they must never include pricing, trial offers or expiry notices, upsell, payment requests, links to payment pages, or the word "free" ([policy 1140.4.8](https://learn.microsoft.com/en-us/legal/marketplace/certification-policies#114048-mobile-experience)).
- Stripe billing lives on the website (`/subscribe`, `/update_cc`); Stripe emails customers about billing. Mention these pages only on the website, never from the bot.

## Tests

- Tests live in `spec/` and use RSpec with Fabrication for factories (`spec/fabricators/`).
- Write tests for all new features and bug fixes.
- Requires a local MongoDB instance (see `config/mongoid.yml`).

## Code Style

- Ruby style is enforced via RuboCop (`.rubocop.yml`). Persistent exceptions live in `.rubocop_todo.yml`.
- Do not add new entries to `.rubocop_todo.yml` for code you write — fix the offenses instead.

## Commits and PRs

- Never push directly to master — always work on a branch and open a PR.
- Squash commits before merging — one logical commit per PR.
