# 04 — `chat_messages` table + migration v70→v71

Status: done

Parent: [PRD](../PRD.md)
Depends on: none (foundation, phase B)

## Goal

Persist conversation threads on the phone so a thread survives Android killing
the app mid-workout — which will happen, because the app sits backgrounded with
the screen off between sets. Without this, you lose the thread while the sets
the agent already wrote are still sitting in your session, which is the
confusing failure mode.

## Where

- New: `lib/database/chat_messages.dart`
- `lib/database/database.dart:699` — `schemaVersion` 70 → 71, plus the manual
  `onUpgrade` branch
- New schema snapshot `lib/database/schema_v71.dart` + `drift_schemas/`

## Tasks

- Define the table:

  ```dart
  class ChatMessages extends Table {
    IntColumn get id => integer().autoIncrement()();
    /// Null = the rolling ad-hoc thread; set = the thread for that workout.
    IntColumn get workoutId => integer().nullable()();
    /// 'user' | 'assistant' | 'tool'
    TextColumn get role => text()();
    TextColumn get content => text().nullable()();
    /// Raw tool_calls JSON as emitted by the model, replayed verbatim.
    TextColumn get toolCalls => text().nullable()();
    /// tool_call_id for role='tool' rows.
    TextColumn get toolCallId => text().nullable()();
    DateTimeColumn get created => dateTime()();
  }
  ```

- Register in the `@DriftDatabase` tables list (`lib/database/database.dart`).
- Bump `schemaVersion` 70 → 71.
- Add a **manual** migration in `onUpgrade`: `from < 71 → CREATE TABLE IF NOT
  EXISTS chat_messages (...)`. Mirror the style of the existing `CREATE TABLE`
  migrations — `FiveThreeOneState._ensureTable()`
  (`lib/fivethreeone/fivethreeone_state.dart:26-49`) is the closest precedent
  for a table added this way.
- Add an index on `(workout_id, created)` — every read is "the thread for this
  workout, in order".
- Generate the v71 schema snapshot and `drift_schemas/` JSON, following how
  earlier snapshots were produced.
- Run codegen (`dart run build_runner build`).
- Add a migration test to `test/database/database_migration_test.dart` covering
  v70 → v71.

## Acceptance

- App builds; `flutter analyze` clean.
- Fresh install creates the table; upgrading a v70 database adds it with no data
  loss.
- Migration test passes.
- **A previously exported CSV still imports unchanged.** `lib/export_data.dart`
  exports `gym_sets` columns only, so a new unrelated table cannot affect it —
  confirm by round-tripping an export taken before the migration.

## Notes

- Purely additive new table, no touch to `gym_sets` — the CLAUDE.md "confirm
  before proceeding if exported data can no longer be reimported" rule does not
  trigger. Still say so in the commit body.
- Do **not** add chat messages to export/import. Conversation scrollback is not
  training data and does not belong in a backup CSV.
- `toolCalls` stores raw provider JSON deliberately: replaying a thread means
  handing the provider back exactly what it sent.
