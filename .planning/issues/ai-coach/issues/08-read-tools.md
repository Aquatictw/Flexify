# 08 — Read tools for deep history

Status: done

Parent: [PRD](../PRD.md)
Depends on: 07

## Goal

Three thin read tools for anything the snapshot deliberately omits. The snapshot
covers *now*; these cover *before*. They are what make retrospective questions
answerable — "how has my bench AMRAP trended?", "what did I do in my last
block?" — without bloating every turn.

## Where

- New: `lib/coach/read_tools.dart`
- Uses the existing aggregation helpers in `lib/database/gym_sets.dart`

## Tasks

- **`get_exercise_history({exercise, limit?})`** — last N sessions for one
  exercise: date, and each working set as weight × reps. Filter `hidden = 0` and
  exclude warmups. Default `limit` 10, cap it. Validate `exercise` against the
  snapshot vocabulary, same error shape as issue 06.
- **`get_records({exercise})`** — reuse `getExerciseRecords()`
  (`lib/database/gym_sets.dart:681`) and `getRepRecords()` (:614). Do not
  reimplement the 1RM formula; the Brzycki expression already lives in
  `ormCol` (:16).
- **`get_block_history({limit?})`** — completed blocks from
  `FiveThreeOneState.getCompletedBlocks()`
  (`lib/fivethreeone/fivethreeone_state.dart:270`): start and end TMs per lift,
  supplementals run, dates. This is what lets it answer "am I actually
  progressing across blocks?"
- **Bound every result.** These feed straight back into the context window; an
  unbounded history dump on a two-year log is a self-inflicted cost and quality
  problem. Truncate and say so in the result: *"showing 10 most recent of 47"*.
- Format results as compact text, not raw JSON — the model reads them, nothing
  parses them.
- Register in the tool set offered by `CoachState` (issue 07). These are always
  available, including with no active workout, since they are read-only.
- Extend the system prompt (issue 02) with when to reach for them: the snapshot
  already carries the current session and the last couple of sessions for lifts
  in play, so a read tool is only for older or wider questions.

## Acceptance

- Each tool returns a bounded, human-readable result.
- `get_records` values match what the app's own records UI shows for the same
  exercise.
- An unknown exercise name returns the same candidate-suggestion error as
  issue 06, not an empty result.
- Asking "how has my bench trended?" in the ad-hoc thread triggers
  `get_exercise_history` rather than being answered from the snapshot alone —
  add this as an eval case.

## Notes

- These are read-only and carry no authority tier; they are safe to offer
  unconditionally.
- Reuse the existing query helpers. Reimplementing 1RM or record logic here
  would give the coach a second, divergent source of truth about your own PRs.
