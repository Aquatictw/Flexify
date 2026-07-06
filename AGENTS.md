# JackedLog - Agent Context

## Database

- Always write migrations manually — never generated ones.
- If the database version changed and previously exported app data can no
  longer be reimported, confirm with me before proceeding.
- Current schema version lives in `lib/database/database.dart`.

## Commits

- **ONE COMMIT PER PHASE.** Squash all work in a phase (research, planning,
  execution, fixes, docs) into a single commit. Never split a phase into
  multiple commits, even if the diff covers several concerns — this rule
  overrides any skill guidance that suggests splitting.
- Format: scoped Conventional Commits, e.g. `fix(widgets): ...`,
  `feat(plan): ...`, `docs: ...`.
- Never commit without an explicit go-ahead from me.

## Orchestration

You are the orchestrator running on an expensive model. Delegate research and
implementation to Codex or parallel subagents (fan out when tasks are
independent) to keep the main context clean; reserve the main context for
coordinating, reviewing, and deciding.

## Agent skills

### Issue tracker

Issues and PRDs live as local markdown under `.planning/issues/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles, each label string equals its name (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `.planning/CONTEXT.md` + `.planning/docs/adr/`. See `docs/agents/domain.md`.

### File routing

Read `.planning/CONTEXT.md` **before** any broad code search — this applies to
you and to every agent you spawn (Explore fan-outs included). Use it for
product language and current status to choose starting files instead of
repo-wide grep sweeps.

## Verifying changes (agents may run this)

The app is tested on a physical Android phone over adb.

- Verify UI and behavior changes by running on the phone (`flutter run -v`)
  and looking at the screen — prefer this over writing or running tests
  unless tests are explicitly requested.
- To see the current screen, run `./scripts/adb-screenshot` — it captures the
  phone display to `.screenshots/screen.png` (gitignored) and prints the
  absolute path. Then Read that path to view the image. Use it whenever a
  change has a visual result; log output alone is not visual verification.
- The phone may be on its lock screen — ask me to unlock it and navigate to
  the target screen before taking screenshots.
- **Never judge performance or animation smoothness in a debug build** —
  debug Flutter is always janky (blur filters especially). Build release and
  `adb install` to assess perf.
- Requires a phone connected with USB debugging (`adb devices` shows a
  `device`).

## Code conventions

- Batch multi-row Drift inserts/updates/reorders in a single transaction —
  never a loop of per-row `insert`/`update` calls (each is its own fsync and
  a known lag source in this app).
- Keep list-item widget keys stable. Never bake refresh counters or other
  volatile values into a `ValueKey`; drive refreshes via props or
  `didUpdateWidget`.
- `.prototypes/` is a local scratch dir for throwaway HTML design prototypes.
  It must stay gitignored and never be committed — this repo is public.

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

*Last updated: 2026-07-06*
