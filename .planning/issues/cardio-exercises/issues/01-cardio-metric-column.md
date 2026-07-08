# 01 — Add `cardio_metric` column + migration v66→v67

Status: ready-for-agent

Parent: [PRD](../PRD.md)
Depends on: none (foundation)

## Goal

Persist the per-exercise **primary measurement** (the featured cardio input).
Store it as a new nullable `cardio_metric TEXT` on `gym_sets`, denormalized onto
every row like `brandName` already is.

Values: `'duration' | 'distance' | 'speed' | 'incline'` (null for weight
exercises). `duration` = the featured field is Time.

## Tasks

- Add `TextColumn get cardioMetric => text().nullable()();` to `GymSets`
  (`lib/database/gym_sets.dart`, alongside `brandName` ~line 684).
- Bump `schemaVersion` 66 → 67 (`lib/database/database.dart:498`).
- Add a **manual** migration in the `onUpgrade` block:
  `from < 67 → ALTER TABLE gym_sets ADD COLUMN cardio_metric TEXT`
  (mirror the exercise_type/brand_name ALTER at `database.dart:193-199`).
- Add the schema snapshot: generate `schema_v67.dart` and the
  `drift_schemas/` JSON (follow how v61/v66 snapshots were produced).
- Export: add `cardio_metric` column (`lib/export_data.dart`, near the existing
  cardio/exerciseType columns ~lines 86-104).
- Import: read `cardio_metric` if present, else null
  (`lib/import_data.dart`, near ~line 260-285).
- Run codegen (`dart run build_runner build`) so Drift companions pick up the
  column.

## Acceptance

- App builds; `flutter analyze` clean.
- Fresh install creates the column; upgrading a v66 DB adds it without data loss.
- A previously-exported CSV (no `cardio_metric`) still imports (column → null).
- New export includes the `cardio_metric` header + values.

## Notes

- Additive nullable column → no reimport break; the CLAUDE.md "confirm before
  proceeding" DB rule does not trigger. Still call it out in the commit body.
