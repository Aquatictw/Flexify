# JackedLog - Agent Context

## CRITICAL RULES - READ FIRST

### Always do manual migration
### If database version has been changed, and previous exported data from app can't be reimported, affirm me.

## Agent skills

### Issue tracker

Issues and PRDs live as local markdown under `.planning/issues/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles, each label string equals its name (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `.planning/CONTEXT.md` + `.planning/docs/adr/`. See `docs/agents/domain.md`.

### File routing

Before broad code search, use `.planning/CONTEXT.md` for product language and current status to choose starting files.

## Inspecting the running app (agents may run this)

The app is tested on a physical Android phone over adb. To see the current
screen, run `./scripts/adb-screenshot` — it captures the phone display to
`.screenshots/screen.png` (gitignored) and prints the absolute path. Then Read
that path to view the image. Use this whenever you need to verify UI, or when
the user asks for an adb screen check. Requires a phone connected with USB
debugging (`adb devices` shows a `device`).

## Server deploys (agents may run these)

The self-hosted server (`server/`) deploys via GHCR + Watchtower: push to `main`
→ GitHub Actions builds the image → Watchtower pulls it. Agent-friendly scripts
in `scripts/` automate the loop:

- `./scripts/prod-deploy` — push main, wait for the image build, trigger the
  container update, verify the new commit is live. Requires a clean worktree.
- `./scripts/prod-status` — health, running commit, pending updates.
- `./scripts/prod-logs [-f] [lines]` / `./scripts/prod-restart` — need SSH.

Config lives in `scripts/prod.env` (copy from `scripts/prod.env.example`).
**`prod.env` is gitignored and must never be committed — this repo is public.**
Never hardcode the server URL, API key, or SSH host anywhere tracked by git.


---

*Last updated: 2026-02-02*
