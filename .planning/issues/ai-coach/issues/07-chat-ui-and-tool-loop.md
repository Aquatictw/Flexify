# 07 — Chat UI + tool loop client

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 04, 05, 06

## Goal

The user-facing half: two entry points, the thread view, and the loop that
drives `/api/chat` → tool execution → `/api/chat` until the model stops calling
tools. After this issue the feature works end to end for session writes.

## Where

- New: `lib/coach/coach_state.dart` (loop + thread), `lib/coach/coach_page.dart`,
  `lib/coach/coach_sheet.dart`, `lib/coach/widgets/`
- `lib/home_page.dart:34,52` — tab registration
- `lib/plan/start_plan_page.dart` — in-workout entry point
- `lib/main.dart` — provider registration

## Tasks

- **Tool loop** (`CoachState`, a `ChangeNotifier` registered in the provider
  tree alongside `FiveThreeOneState`):
  1. Append the user message to `chat_messages`.
  2. Build `messages` from the thread + `tools` from the offered set, append the
     snapshot (issue 05), POST to `/api/chat` with
     `Authorization: Bearer <JACKED_API_KEY>`.
  3. If the reply has `tool_calls`: execute each locally, persist an
     `assistant` row with `toolCalls` and one `tool` row per result, loop.
  4. If not: persist the assistant text and stop.
  - **Cap at 10 iterations.** On exceeding it, stop and show "gave up after 10
    steps" in the thread. This is a correctness guard, not a cost one — an
    uncapped loop hangs the UI mid-workout with no way out.
- **Tool offering is contextual**: when there is no active workout, omit
  `apply_session_changes` from `tools` entirely rather than offering it and
  rejecting the call. When there is no active block, omit the TM-related ops.
  Removing a capability beats refusing it.
- **Thread scoping**: the in-workout sheet reads/writes `workoutId = <current>`;
  the tab reads/writes `workoutId IS NULL`. Two threads, never mixed.
- **Entry points:**
  - `CoachPage` added to the `settings.tabs` vocabulary (`lib/home_page.dart:34`
    splits the comma list; `hideTab` at :52 already handles removal) — the
    ad-hoc thread.
  - An icon/FAB on `start_plan_page` opening `CoachSheet` as a modal bottom
    sheet over the live workout, so sets appear behind it as tools resolve.
- **Rendering**: user bubbles, assistant markdown, and a distinct compact style
  for tool results — `✓ Added Bench Press — 3 sets` / `✓ 5×65 kg, 5×75 kg,
  5×85 kg`. These ticks are the progress UI; there is no streaming
  (PRD decision 10). Show a thinking indicator between turns.
- **Refresh the workout** after a successful `apply_session_changes` so the card
  behind the sheet updates — `ExerciseSetsCard` already re-reads on
  `refreshToken` change (`lib/plan/exercise_sets_card.dart:96-100`); reuse that
  path rather than inventing a new one.
- **Failure handling**: on network error or non-2xx, show the error in the
  thread, keep the user's text in the composer, offer Retry. No queuing —
  coaching advice twenty minutes late is worthless.
- Persist the server URL and key alongside the existing backup settings; do not
  add a second configuration surface.

## Acceptance

- Tab appears in the tab list, can be hidden via the existing long-press flow.
- In-workout FAB opens the sheet over the live session.
- "Add my prescribed bench work 5% lighter" writes sets, shows tool ticks, and
  the card behind the sheet updates without a manual refresh.
- Killing the app mid-thread and reopening restores the workout thread from
  `chat_messages`.
- With no active workout, the write tool is absent from the request payload.
- Airplane mode produces an in-thread error with a working Retry.
- A model that loops stops at 10 iterations with a visible message.
- Verify on device per CLAUDE.md — screenshot the sheet over an active workout.

## Notes

- Keep list-item keys stable in the message list; no refresh counters in
  `ValueKey` (CLAUDE.md).
- The loop is the one place that can spend money in a runaway; the iteration cap
  is the only thing standing in for the spend guard we deliberately skipped.
