# 05 — Route cardio exercises to the cardio graph + Speed metric

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 01

## Goal

Opening a cardio exercise's progress graph shows the existing cardio metric
picker (already built), not the strength page. Ensure a **Speed** view exists.

## Where

- `lib/graph/cardio_page.dart` — full cardio graph, `metric` default
  `CardioMetric.pace` (44), selector over `CardioMetric.values` (255).
- `lib/graph/strength_page.dart` — strength graph.
- `enum CardioMetric { pace, distance, duration, incline, inclineAdjustedPace }`
  (`lib/constants.dart:16`); `getCardio`/`getCardioData`
  (`lib/database/gym_sets.dart:19-103`).
- Wherever a graph is opened from an exercise tile/list (strength_page,
  exercise_tile, history) — find the navigation and branch on `cardio`.

## Tasks

- When opening a graph for an exercise with `cardio=1`, navigate to
  `CardioPage` instead of `StrengthPage`.
- Confirm the "Speed" concept is presentable: `getCardio` computes
  `pace = distance/duration` (that is speed, km/h). Relabel the picker entry to
  "Speed" for user-facing text, or add a dedicated `speed` case if `pace` is
  used elsewhere with pace semantics — verify before renaming.
- No new aggregation math needed (conversion already in `getCardioData`).

## Acceptance

- Cardio exercise → cardio graph with metric picker (Distance/Time/Speed/
  Incline visible and plotting).
- Weight exercise → strength graph unchanged.
- `flutter analyze` clean; verify a cardio graph renders on device.

## Notes

- This issue is small because the cardio graph already exists; it is mostly
  routing + a label check.
