# 07 — Cardio in saved plans/routines

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 01, 02, 03

## Goal

Cardio exercises can live in saved plans. The per-exercise set-count config is
meaningless for cardio, so hide it; starting the plan creates 1 bout.

## Where

- `PlanExercises` join table — `maxSets`, `warmupSets` per exercise
  (`lib/database/plan_exercises.dart:5-14`).
- Plan editor UI (where exercises are added to a plan and set counts configured)
  — find via the plan flow (`lib/plan/…`).
- `lib/plan/start_plan_page.dart` — `_buildExerciseList` (530), start flow that
  feeds `ExerciseSetsCard`; auto-set-creation lands in
  `exercise_sets_card.dart` `_loadSetsData` (issue 03 already makes cardio → 1
  bout).

## Tasks

- Plan editor: when an exercise is cardio, hide the set-count / warmup-sets
  controls (show nothing or a "Cardio" note instead).
- Adding a cardio exercise to a plan persists with the set-count fields left at
  defaults/null; they are simply ignored downstream.
- Starting a plan: confirm cardio exercises get 1 bout (relies on issue-03
  branch, which ignores `maxSets` for cardio) — add a guard here if the plan
  path pre-seeds sets before the card loads.

## Acceptance

- Add a cardio exercise to a routine → no set-count config shown.
- Start that routine → cardio exercise appears as one bout, weight exercises get
  their configured sets.
- Weight-only plans unchanged.
- `flutter analyze` clean; verify a mixed plan (weights + cardio) on device.
