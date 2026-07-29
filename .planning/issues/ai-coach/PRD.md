# PRD: AI Coach Agent

Status: ready-for-agent

## Summary

An in-app chat coach with 5/3/1 expertise that can read your live training
state and write sets into the workout you are currently doing.

Three things it does:

1. **Answers programming questions** grounded in *5/3/1 Forever* — leader/anchor
   choice, TM selection, supplemental and assistance rules, conditioning, recovery.
2. **Writes prescribed sets into the live session** — "today is 5/3/1 bench,
   add the prescribed work but 5% lighter", "add a set at 90% TM × 5".
3. **Proposes block-level changes** — TM corrections and bumps, cycle position,
   supplemental template — always behind an explicit confirmation.

The LLM runs behind a proxy route on the existing self-hosted server; the agent
loop and all tool execution run on the phone against Drift.

Ships as **three phases / three commits** (per repo commit rule). Issues below
are grouped by phase; each phase squashes to one commit.

## Background: what already exists

- **`gym_sets.hidden` is already the "prescribed but not performed" state.**
  `start_plan_page.dart:274` — *"Update both completed (hidden=0) and
  uncompleted (hidden=1) sets, but not tombstones (sequence=-1)"*. Every
  history, graph, record and dashboard query filters `hidden = 0` (~20 call
  sites in `lib/database/gym_sets.dart`, `lib/graph/`, `lib/plan/plan_state.dart`).
  The agent therefore needs **no new set state** — it writes `hidden=1` rows and
  completing them through the existing UI flips them to `hidden=0`.
- **All 5/3/1 percentage math is already encoded and trusted** —
  `lib/fivethreeone/schemes.dart` (scheme tables, cycle constants, TM bump
  steps) and `lib/fivethreeone/main_lifts.dart` (`mainWorkPrescription()` at
  :54, `roundToPlate()` at :42, `mainLiftTmKeys` at :9).
- **Block state** is `five_three_one_blocks` (`lib/database/fivethreeone_blocks.dart`):
  four TMs, `current_cycle` 0-4, `current_week` 1-3, `leader_supplemental`,
  `anchor_supplemental`, `tm_bumps`.
- **Server auth already covers new routes.** `authMiddleware`
  (`server/lib/middleware/auth.dart:125`) is applied to the whole pipeline in
  `server/bin/server.dart:78-82` and accepts `Bearer <JACKED_API_KEY>` for app
  traffic (:180-188). A new `/api/chat` route inherits it with no work.
- Server is Dart/shelf (`server/`), currently backup + dashboard only. `http`
  is already a dependency in the app (`pubspec.yaml`).
- Tabs are a user-editable comma-separated list in `settings.tabs`
  (`lib/home_page.dart:34`, `hideTab` at :52), so adding a tab is idiomatic and
  hideable.
- `531forever.pdf` has an Acrobat ClearScan **OCR text layer** — 283 pages,
  ~539k chars (~135k tokens), extractable with `pdftotext`.

## Locked design decisions

1. **Write target — real rows.** The agent writes real `gym_sets` rows with
   `hidden=1`. No new set-state concept, no change to what a `gym_sets` row
   means, no migration for this part.
2. **Tiered authority.** Auto-apply anything confined to `hidden=1` rows in the
   *current* workout. Require explicit confirmation for anything touching
   performed (`hidden=0`) rows, training maxes, cycle position, or supplemental
   template. **The tool boundary is the authority boundary** — the tier is
   visible in the tool name, never buried in argument discrimination.
3. **Model never emits a number.** Tool arguments carry a tagged *weight spec*:
   `{pct_of_tm}` | `{pct_of_prescribed}` | `{pct_of_last_session}` |
   `{absolute}`. Dart resolves each against the active block and history, then
   calls `roundToPlate()`. Arithmetic and plate rounding stay in tested code.
4. **Server is a stateless proxy; the loop runs on the phone.** The server holds
   the provider key and the knowledge doc, assembles the system prompt, and
   forwards. The phone owns message history and the tool loop, so every tool
   call is a local Dart function against Drift — no bidirectional session
   protocol, and the book never ships in the APK.
5. **State is pushed, not pulled.** Every request appends a compact session
   snapshot *after* the cached knowledge prefix. Read tools exist for deep
   history only.
6. **Threads are short-lived.** One thread per `workout_id`, plus one rolling
   ad-hoc thread for pre-workout questions. Continuity across weeks comes from
   the database, not from scrollback. No compaction is ever implemented.
7. **Full block authority, behind confirmation.** TM, cycle position and
   supplemental are all reachable via `propose_block_changes`, always confirmed.
8. **Knowledge doc is prose-only, ~115k tokens.** All OCR'd numeric set tables
   are stripped book-wide — the script font renders percentages as `rO"/o` (70%)
   and `'10"/o` (90%), which is a correctness hazard next to a barbell. Correct
   numbers come from a `schemes.dart`-derived reference instead.
   *Revised 2026-07-29:* the original ~48k estimate assumed the set tables were
   the bulk of the book. They are not — 73% of the raw `pdftotext` output is
   long prose lines, so stripping every table plus the spec'd page ranges still
   leaves ~115k tokens (measured, not chars÷4). Shipping full size was chosen
   deliberately: Part 2's ~40 template chapters are ~55k of it and the coach is
   required to discuss non-representable templates knowledgeably. Prompt caching
   is verified working (115,421 cached tokens on the second request, $0.289 cold
   → $0.024 warm), which is what makes the size affordable.
9. **Model chosen by eval, not by preference.** OpenAI-compatible dialect via
   OpenRouter; model is one env var; a golden-set harness asserts structurally
   on emitted tool calls.
10. **Non-streaming.** Plain JSON request/response; resolved tool calls are the
    progress UI.
11. **Closed exercise vocabulary.** The snapshot ships existing exercise names;
    unknown names are rejected with a retryable tool error. Creating a genuinely
    new exercise requires an explicit flag and lands in the confirm tier.
12. **Units are never in tool arguments** — inherited from `block.unit` (main
    lifts), the exercise's most recent set (accessories), then
    `settings.strengthUnit`.
13. **Coach stance: compliant on session, doctrinal on block.** Session-level
    requests execute without argument. Block-level requests get one sentence of
    doctrine first, then the proposal.
14. **No undo.** Agent-written sets are ordinary rows; edit them by hand in the
    existing workout UI.
15. **No spend guard.** Single user behind `JACKED_API_KEY`. The tool loop is
    still capped (~10 iterations) for *correctness* — an uncapped loop hangs the
    chat UI.

## Out of scope

- Streaming responses.
- Voice input.
- Any template the app cannot represent being *written* — the coach may discuss
  templates outside `schemes.dart`, but must say plainly they are not
  representable and offer the closest supported alternative.
- Multi-user, per-user keys, or rate limiting.
- Server-side conversation storage or analytics.
- Extending `schemes.dart` with new supplemental templates (separate feature).

## Migration / data safety

- Adds one table, `chat_messages`; schema **v70 → v71**
  (`lib/database/database.dart:699`, manual migration only).
- Purely additive new table. `lib/export_data.dart` exports `gym_sets` columns
  only, so **previously exported data still re-imports unchanged** — the
  CLAUDE.md "confirm before proceeding" DB rule does not trigger.
- No changes to `gym_sets`, `plans`, `plan_exercises`, or
  `five_three_one_blocks` schemas.

## Security / repo hygiene

- **`531forever.pdf` must be gitignored.** This repo is public and the file is
  currently sitting untracked in the repo root.
- The derived knowledge doc must also stay out of git and out of the APK. It
  lives on the server, mounted from a path in `prod.env`.
- `OPENROUTER_API_KEY` is a new server env var; it belongs in `prod.env`
  (already gitignored) and must never appear in tracked files.

## Acceptance (feature-level)

- With an active block and an active workout: *"today is 5/3/1 bench day, add
  the prescribed work but 5% lighter"* adds a Bench Press exercise to the live
  session with three `hidden=1` sets at the correct percentages minus 5%,
  correctly plate-rounded in the block's unit.
- *"add a set at 90% TM × 5"* appends one more set to that existing exercise.
- *"add 3×10 lat pulldown at 60kg"* adds an accessory with no TM involvement.
- Asking for a TM change mid-cycle produces one sentence of doctrine, then a
  confirmation card that states whether it counts as a cycle bump; nothing is
  written until confirmed.
- A question with no active workout ("should I switch to an FSL leader?") is
  answered from the book, with write tools not offered at all.
- Naming an exercise that does not exist is rejected and retried, never forked.
- The golden-set harness passes on the chosen model.
- Verified on device per CLAUDE.md.

## Delivery

| Phase | Issues | Commit |
| ----- | ------ | ------ |
| A — Knowledge + proxy + eval | 01, 02, 03 | `feat(server): 5/3/1 coach proxy and knowledge base` |
| B — App chat with session writes | 04, 05, 06, 07 | `feat(coach): in-workout AI coach with session writes` |
| C — Read tools + block authority | 08, 09 | `feat(coach): history tools and block-level proposals` |

Phase numbers to be assigned by the maintainer per the running sequence.

## Issues

See `issues/` — 01…09.
