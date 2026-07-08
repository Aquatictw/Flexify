# 02 — Add-exercise: Cardio type button + primary-metric picker; lock type on edit

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: 01

## Goal

Let the user create a cardio exercise from the add-exercise form and edit its
metadata later, with type locked after creation.

## Tasks

### Add-exercise form — `lib/graph/add_exercise_page.dart`

- Add a 4th entry to `exerciseTypes` (lines 35-39):
  `(value: 'cardio', label: 'Cardio', icon: Icons.directions_run)`.
- Make the type row **horizontally scrollable** (wrap the 3-across Row at
  lines 191-263 in a `SingleChildScrollView(scrollDirection: Axis.horizontal)`
  so the 4th button reveals by scrolling right). Keep the existing three
  buttons' look unchanged.
- When `exerciseType == 'cardio'`:
  - Reveal the **Brand Name** field (currently gated to `machine` at
    lines 266-291) — extend the gate to `machine || cardio`.
  - Reveal a **Primary Measurement** selector: Time / Distance / Speed /
    Incline → sets a new `cardioMetric` state var (default `'duration'`).
- On `save()` (lines 548-579): when cardio, insert with
  `cardio: const Value(true)`, `cardioMetric: Value(cardioMetric)`, and leave
  weight/reps at 0 (unchanged). Non-cardio unchanged (`cardio: false`,
  `cardioMetric: null`).

### Edit-exercise screen — `lib/graph/edit_graph_page.dart`

- Mirror the Cardio type button and Primary Measurement selector.
- **Lock Weight↔Cardio**: disable/grey the type buttons for an existing
  exercise (the type comes from the loaded row). Brand / primary / name / rest
  remain editable. Persist `cardioMetric` changes on save (~lines 537-539).

## Acceptance

- Type row scrolls to reveal Cardio; picking it shows Brand + Primary picker.
- Saving creates a hidden template row with `cardio=1` and the chosen
  `cardio_metric`.
- Editing a cardio exercise: type buttons are locked; changing primary/brand
  persists.
- Weight exercises: no behavior change.
- `flutter analyze` clean; verify on device per CLAUDE.md.

## Notes

- Primary options map to `cardio_metric` values: Time→`duration`,
  Distance→`distance`, Speed→`speed`, Incline→`incline`.
