# 06 — Weight-spec resolver + `apply_session_changes`

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 05

## Goal

The auto-apply write tier. One tool, `apply_session_changes(ops[])`, whose ops
are confined to `hidden=1` rows in the **current** workout, executed in a single
Drift transaction. Plus the resolver that turns the model's tagged weight specs
into actual bar weights.

This is the issue where "add the prescribed work but 5% lighter" becomes rows.

## Where

- New: `lib/coach/weight_spec.dart`
- New: `lib/coach/session_tools.dart`
- Uses: `lib/fivethreeone/main_lifts.dart` (`roundToPlate` :42,
  `mainWorkPrescription` :54, `mainLiftTmKeys` :9), `lib/database/exercise_names.dart`

## Tasks

- **Weight spec union** — exactly four variants, no bare numbers accepted:

  | Variant | Resolves to |
  | ------- | ----------- |
  | `{"pct_of_tm": 0.90}` | `block` TM for that lift × 0.90 |
  | `{"pct_of_prescribed": -0.05}` | the set's `mainWorkPrescription()` weight × 0.95 |
  | `{"pct_of_last_session": -0.05}` | that exercise's matching set last session × 0.95 |
  | `{"absolute": 60}` | 60, as-is |

  Every variant terminates in `roundToPlate(weight, unit)`. A spec that cannot
  resolve (no TM for a non-main lift, no prior session) returns a **tool error
  string the model can act on**, not an exception — e.g. *"Lat Pulldown has no
  training max; use an absolute weight or pct_of_last_session."*

- **Unit resolution, never from the model** (PRD decision 12): main lifts →
  `block.unit`; accessories → the unit of that exercise's most recent set;
  fallback → `settings.strengthUnit`. `roundToPlate` branches on this (2.5 kg vs
  5 lb), so a wrong unit changes the rounding, not just the label.

- **Op types** for `apply_session_changes`:
  - `add_exercise {exercise, sets: [{weight_spec, reps, amrap?}]}`
  - `add_sets {exercise, sets: [...]}` — appends to an exercise already present
  - `edit_set {exercise, set_index, weight_spec?, reps?}`
  - `remove_sets {exercise, set_indices}`

- **Guard rails enforced in code, not prompt:**
  - Every op targets the current `workoutId`. Reject anything else.
  - Only `hidden = 1` rows may be edited or removed. A request touching a
    performed set returns a tool error saying it needs `propose_block_changes`.
  - `exercise` must be in the snapshot's `exerciseVocabulary`. Unknown → tool
    error with the nearest candidates: *"unknown exercise 'Bench'; did you mean
    'Bench Press'?"* Do **not** fuzzy-match and proceed — `mainLiftTmKeys` is
    deliberately exact-match to stop 'Squat' resolving to 'Front Squat'.
  - Creating a genuinely new exercise requires `create_new: true` **and** is
    escalated to the confirm tier (issue 09), never auto-applied.

- **Single transaction.** Build all rows, write once. Per CLAUDE.md: *"Batch
  multi-row Drift inserts/updates/reorders in a single transaction — never a
  loop of per-row insert/update calls."* This is the whole reason the write tool
  is batched rather than one-op-per-call.

- New rows: `hidden: true`, correct `workoutId`, `sequence` matching the
  exercise's position, `setOrder` continuing the existing sequence, `name`
  passed through `normalizeExerciseName()`
  (`lib/database/exercise_names.dart`).

- Return a **structured tool result** listing what was written — exercise, and
  each set's resolved weight × reps with unit. The model must report weights
  from this result, never from its own arithmetic; that rule also lives in the
  system prompt (issue 02).

## Acceptance

- Unit tests for the resolver: each of the four variants, plate rounding in kg
  and lb, and both unresolvable cases returning errors rather than throwing.
- "Prescribed minus 5%" for Leader 2 week 2 bench (TM 100 kg) yields
  70/80/90 × 0.95 → plate-rounded, in one transaction.
- An op targeting a `hidden=0` set is rejected with a tool error.
- An op targeting a different `workoutId` is rejected.
- Unknown exercise name returns candidates and writes nothing.
- No tool argument anywhere carries a unit or a bare resolved weight.
- Verify on device per CLAUDE.md — sets appear in the live card with correct
  weights.

## Notes

- Keep list-item widget keys stable when the card rebuilds after a write; do not
  bake a refresh counter into a `ValueKey` (CLAUDE.md).
- Tool errors are a feature: they are how the model self-corrects within the
  loop instead of confidently writing something wrong.
