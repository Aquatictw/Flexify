# 05 — Session snapshot builder

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: none (foundation, phase B)

## Goal

Build the compact JSON blob describing your current training state, appended to
every chat request *after* the cached knowledge prefix. This is what lets the
agent answer without a read-tool round trip while you are standing under a bar.

Target ~1–2k tokens. It carries the *current* picture only; anything historical
is a read tool (issue 08).

## Where

- New: `lib/coach/session_snapshot.dart`
- Reads: `FiveThreeOneState.activeBlock`, `db.gymSets`, `db.workouts`,
  `SettingsState`

## Tasks

- Define the snapshot shape and **freeze it** — issue 03's cases are literals of
  this shape, so changes here invalidate the harness:

  ```jsonc
  {
    "unit": "kg",                       // settings.strengthUnit
    "block": {                          // null when no active block
      "cycle": "Leader 2", "cycleIndex": 1, "week": 2,
      "mainScheme": "5's PRO", "supplemental": "BBB 5x10",
      "tms": {"squat": 140, "bench": 100, "deadlift": 180, "press": 65},
      "tmBumps": 1
    },
    "workout": {                        // null when no active workout
      "id": 412,
      "exercises": [
        {"name": "Bench Press", "sets": [
          {"weight": 65, "reps": 5, "done": true},
          {"weight": 75, "reps": 5, "done": false}
        ]}
      ]
    },
    "prescription": [ ... ],            // mainWorkPrescription() for main lifts present
    "recent": {                         // last 1-2 sessions for lifts in play
      "Bench Press": [{"date": "2026-07-22", "sets": ["5x65", "5x75", "8x85"]}]
    },
    "exerciseVocabulary": ["Bench Press", "Squat", "Lat Pulldown", ...]
  }
  ```

- **`done`** maps to `hidden == false`. Do not leak the column name; the model
  should reason about performed vs prescribed, not about schema.
- Exclude tombstone rows (`sequence == -1`, `reps == -1`) — see
  `lib/plan/start_plan_page.dart:606-618`.
- **`exerciseVocabulary`**: distinct `gym_sets.name` values. This is the closed
  vocabulary issue 06 validates against. Cap it (most-recently-used first) if it
  grows past a few hundred entries.
- **`prescription`**: call `mainWorkPrescription()`
  (`lib/fivethreeone/main_lifts.dart:54`) for each main lift present in the
  session, so `{pct_of_prescribed}` has a defined base the model can see.
- **`recent`**: last 1–2 sessions for the exercises in the current workout only,
  not all four main lifts. Filter `hidden = 0`.
- Build it in **one or two queries**, not per-exercise loops — this runs on
  every turn (`lib/database/query_helpers.dart` has the existing precedent for
  batching these reads).
- Serialize deterministically (sorted keys) so it is diffable in logs and stable
  across turns.

## Acceptance

- With an active block and workout, the snapshot renders every field above and
  round-trips through `jsonEncode`/`jsonDecode`.
- With no active block, `block` is null and the snapshot is still valid.
- With no active workout, `workout` and `prescription` are null.
- Tombstone rows never appear in `workout.exercises`.
- Token count of a realistic snapshot is under ~2k — measure and record it.
- Two consecutive builds with unchanged data produce byte-identical output.

## Notes

- This goes **after** the system prompt in the message array. Anything placed
  ahead of the knowledge doc invalidates the cache on every turn.
- Resist adding fields "while we're here". Every field is paid for on every turn
  of every conversation, forever.
