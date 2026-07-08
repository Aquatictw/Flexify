# 03 — Active-workout cardio card (full-block bouts)

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 01, 02

## Goal

In an active workout, a cardio exercise renders full-block bouts — Time,
Distance, Speed, Incline, Done — instead of weight×reps set rows. This is the
core new UI.

## Where

- `lib/plan/exercise_sets_card.dart` — owns per-exercise sets, `_loadSetsData`
  (95-278), the `ReorderableListView` of `SetRow`s (1104-1165), and the
  Warmup/Drop/Working add buttons (1166-1308).
- New widget `lib/widgets/sets/cardio_bout.dart` (a full block, sibling to
  `set_row.dart`).

## Tasks

- **Branch on `cardio`** in `ExerciseSetsCard.build`: if the exercise is cardio,
  render a vertical stack of `CardioBout` blocks + a subtle "+ Add bout" button,
  instead of the `SetRow` list and Warmup/Drop/Working buttons.
- **Auto-create 1 bout, not `maxSets`**: in `_loadSetsData` (loop at 196-244),
  when cardio, insert a single row (`hidden:true`, `cardio:true`,
  `cardioMetric` copied from the reference/template row like `brandName` is at
  131-132/228-229), seeded from the previous entry if any.
- **`CardioBout` block** renders, ordered by the exercise's `cardioMetric`
  (featured field first, large; others smaller below):
  - **Time** (mm:ss) — the anchor. Store as fractional minutes
    (`min + sec/60`), matching `edit_set_page.dart:591-592`.
  - **Distance** — unit from `settings.cardioUnit` (km/mi).
  - **Speed** — derived `distance ÷ duration` (convert to km/h or mph),
    editable. **Recompute rule**: edit Speed → Distance = speed×time; edit
    Distance → Speed display recomputes; edit Time → rescale Distance holding
    Speed. Speed is display-only state, never written to DB.
  - **Incline** — integer `%`.
  - **Done** toggle (reuse `CompleteButton` semantics; sets `hidden=false`).
- Persist edits via the existing `_updateSet` path (write duration/distance/
  incline; never write speed).
- Multi-bout: rows distinguished by `setOrder` (existing column). "+ Add bout"
  inserts another cardio row.

## Acceptance

- Adding a cardio exercise shows exactly one full block, primary field featured.
- Time-anchored recompute behaves: edit speed→distance moves; edit
  distance→speed moves; edit time→distance rescales.
- Speed is never persisted; reopening recomputes it from stored distance/time.
- +bout adds a second full block; Done marks a bout complete.
- Weight exercises unchanged.
- Verify on device (recompute + persistence) per CLAUDE.md.

## Notes

- Keep list-item keys stable (`ValueKey('bout_${savedSetId ?? order}')`) — no
  refresh counters (CLAUDE.md).
- Batch any multi-row insert in a single transaction (CLAUDE.md).
