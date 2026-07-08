# JackedLog Context

This file records the project's domain language, product context, and current architectural assumptions for engineering skills.

## Glossary

- **Cardio exercise** — an exercise with `gym_sets.cardio = true`. Logged by
  Time/Distance/Speed/Incline instead of weight×reps. Backend, graph
  (`cardio_page.dart`), and `cardioUnit` setting predate JackedLog (Flexify
  fork); the custom UI is being wired up. See `issues/cardio-exercises/`.
- **Primary measurement** (`cardio_metric` column) — the *featured input* field
  of a cardio exercise in the active-workout card (e.g. treadmill = Time). It
  only controls visual prominence; all metrics still drive records and can be
  graphed.
- **Bout** — one cardio entry (a `gym_sets` row). A cardio exercise may hold
  multiple bouts, each rendered as a full block, not a compact set row.
- **`duration`** — stored as fractional minutes (5m30s = `5.5`).
- **Exercise type** — `exercise_type` string on `gym_sets`: `free_weight` /
  `machine` / `cable` (+ Cardio as a 4th add-form button). `brand_name` applies
  to machines and cardio machines.

## Current Status

Add high-level product or technical status here when it helps future work.

## Notes

Use ADRs under `.planning/docs/adr/` for decisions that should be preserved over time.
