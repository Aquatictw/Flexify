# 06 — Read-only cardio display in history/detail/lists

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 01, 03

## Goal

Logged cardio renders correctly (not blank weight×reps) everywhere sets are
shown read-only.

## Where (surfaces to make cardio-aware)

- `lib/workouts/workout_detail_page.dart` — view-mode `_buildSetTile` (1864)
  and `_buildExerciseGroup` (1585); edit-mode `_buildEditableExerciseCard`
  (1368) using `SetRow` (1447-1459) — edit mode should reuse the cardio bout
  block from issue 03 for cardio exercises.
- `lib/sets/history_list.dart` (~300-316, brand chips) — cardio summary line.
- `lib/plan/exercise_tile.dart`, `lib/graph/graph_tile.dart`,
  `lib/graph/strength_page.dart` — list summaries.

## Tasks

- Read-only cardio tile: show Time / Distance / Speed / Incline (Speed derived,
  units from `settings.cardioUnit`). Summary line shows all present metrics —
  primary is **not** forced first (primary = workout input only), e.g.
  `32:10 · 5.2 km · 2%`.
- Detail view mode: cardio exercises render cardio tiles instead of
  weight×reps.
- Detail edit mode: cardio exercises render the issue-03 bout block; weight
  exercises keep `SetRow`.
- Skip weight-only chrome (reps, weight unit) for cardio rows.

## Acceptance

- End a workout with a cardio exercise → detail view shows the cardio metrics,
  not empty/0 kg × 0 reps.
- Editing that ended workout shows editable cardio bouts.
- History list shows a sensible cardio summary line with brand chip.
- Weight rendering unchanged.
- `flutter analyze` clean; verify on device across history + detail.
