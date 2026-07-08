# PRD: Cardio Exercises

Status: ready-for-agent

## Summary

Surface first-class cardio exercises in JackedLog. The data layer, cardio graph
page, and unit handling already exist (this is a Flexify fork); the gap is the
custom JackedLog UI — the add-exercise form, the active-workout card, PR
records, and read-only history rendering never account for cardio.

A cardio exercise supports **custom brand machines** just like weight machines
(e.g. a specific treadmill). In an active workout it does **not** render weight×reps
set rows; instead each bout is a full block with Time / Distance / Speed / Incline.

Ships as **one phase / one commit** (per repo commit rule). Issues below are task
decomposition within that single phase, not separate commits.

## Background: what already exists

- `gym_sets` columns: `cardio` (bool), `distance`, `duration` (RealColumns),
  `incline` (nullable Int). `duration` is stored as **fractional minutes**
  (5m30s = `5.5`). — `lib/database/gym_sets.dart:662-670`
- Cardio graph page with metric selector already built:
  `lib/graph/cardio_page.dart`; `enum CardioMetric { pace, distance, duration,
  incline, inclineAdjustedPace }` (`lib/constants.dart:16`); aggregation
  `getCardio` / `getCardioData` (`lib/database/gym_sets.dart:19-103`).
- Global distance unit: `settings.cardioUnit` (default `km`) —
  `lib/database/settings.dart:8`, `lib/constants.dart:50`.
- Cardio input fields exist only in the legacy edit-set dialog
  (`lib/sets/edit_set_page.dart` `buildCardioFields()` line 255) — NOT in the
  custom active-workout card.
- Export/import already round-trips cardio fields
  (`lib/export_data.dart:101-104`, `lib/import_data.dart:260`).
- Records service **explicitly excludes cardio** (`hidden=0 AND warmup=0 AND
  cardio=0`) — `lib/records/records_service.dart:104-115`.

## Locked design decisions

1. **Type selector** — Cardio is a 4th button in a **horizontally-scrollable**
   type row on the add-exercise form; existing Free Weight / Machine / Cable
   untouched. Selecting Cardio sets `cardio=true` and reveals the Brand Name
   field (cardio machines get brands) plus a **primary-measurement** picker.
2. **Metrics** — Time, Distance, Speed, Incline. Related by
   `distance = speed × time`. **Time is the anchor**: editing Speed recomputes
   Distance; editing Distance recomputes Speed; editing Time rescales Distance
   (holds Speed). Incline is independent. Every field stays overridable.
3. **Speed is never stored** — always derived `distance ÷ duration`. No new
   metric column.
4. **Primary measurement** = *featured input only* — the large top field in the
   workout card; the others render smaller below it. It does **not** gate
   records or graph. Stored per-exercise in a new `cardio_metric` column
   (denormalized onto each row, like `brandName`).
5. **Bouts** — a cardio exercise may hold multiple bouts, but each bout is a
   **full expanded block** (never a squashed row); add-bout is a subtle
   secondary action. Adding cardio auto-creates **1** bout (not `maxSets`).
6. **Units** — global `cardioUnit` (km/mi) drives distance; Speed follows
   (km/h ↔ mph); Incline is `%`; Time is mm:ss.
7. **PRs** — max is best for **all** four metrics (longest time, longest
   distance, top speed, steepest incline); independent badges.
8. **Plans** — cardio can be added to saved plans/routines; the per-exercise
   set-count config is hidden for cardio; starting the plan creates 1 bout.
9. **Type locked after creation** — Weight↔Cardio is disabled on the edit
   screen once an exercise exists; name / brand / primary / rest stay editable.

## Out of scope

- Interval-specific UX beyond plain multi-bout blocks.
- Calories / heart-rate / resistance metrics.
- Per-exercise distance units (global only).
- Changing an existing exercise's type after creation.

## Migration / data safety

- Adds one nullable `cardio_metric TEXT` column; schema **v66 → v67**
  (`lib/database/database.dart`, manual migration only).
- Additive nullable column → previously exported data still re-imports
  (missing column reads as null). No reimport break; no need to invoke the
  "confirm before proceeding" DB rule. Add `cardio_metric` to export/import
  and a new schema snapshot (`schema_v67.dart` + `drift_schemas/`).

## Acceptance (feature-level)

- Create a cardio exercise (e.g. "Treadmill", brand "Life Fitness", primary
  Time) from the add-exercise form.
- Add it to an active workout → one full cardio block, Time featured, editable
  Distance/Speed/Incline with Time-anchored recompute, a Done toggle, and a
  subtle +bout button.
- Log it, end the workout → history/detail renders the cardio block correctly
  (not blank weight×reps).
- Cardio PR badges appear on new maxima.
- Its progress graph opens the cardio metric picker.
- Add it to a saved plan → no set-count config shown; starting creates 1 bout.
- Edit screen: Weight↔Cardio is locked; brand/primary/name/rest editable.

## Issues

See `issues/` — 01…07.
