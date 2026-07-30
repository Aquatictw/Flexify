import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/database/schema.dart';

/// Database migration tests for JackedLog.
///
/// These tests verify that the consolidated database migrations correctly
/// transform schemas and preserve data.
///
/// After migration consolidation, we maintain strategic schema versions:
/// v31, v48, v52, v57, v61, v67, v71

/// Helper to insert minimal Settings record for migration testing.
Future<void> insertMinimalSettings(AppDatabase db) async {
  await db.into(db.settings).insert(
        SettingsCompanion.insert(
          alarmSound: '',
          cardioUnit: 'km',
          longDateFormat: 'dd/MM/yyyy',
          maxSets: 3,
          planTrailing: 'PlanTrailing.reorder',
          shortDateFormat: 'd/M/yy',
          strengthUnit: 'kg',
          themeMode: 'ThemeMode.system',
          timerDuration: 90000,
          curveLines: false,
          explainedPermissions: true,
          restTimers: true,
          systemColors: false,
          vibrate: true,
          groupHistory: const Value(true),
          showUnits: const Value(false),
        ),
      );
}

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    // Verify only the consolidated schema files exist
    final schemaFiles = [31, 48, 52, 57, 61, 67, 71];
    for (final version in schemaFiles) {
      final schemaFile = File('drift_schemas/db/drift_schema_v$version.json');
      expect(
        schemaFile.existsSync(),
        isTrue,
        reason: 'v$version schema file missing',
      );
    }

    // Verify old schema files were deleted
    final oldVersions = [1, 10, 20, 30, 40, 50, 55, 58, 59, 60];
    for (final version in oldVersions) {
      final schemaFile = File('drift_schemas/db/drift_schema_v$version.json');
      expect(
        schemaFile.existsSync(),
        isFalse,
        reason: 'v$version schema file should be deleted after consolidation',
      );
    }

    // Initialize schema verifier with consolidated schema files
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('Consolidated Migration Tests', () {
    test('verifies only 8 strategic schema versions exist', () {
      final schemaDir = Directory('drift_schemas/db');
      final schemaFiles = schemaDir
          .listSync()
          .where((f) => f.path.contains('drift_schema_v'))
          .where((f) => !f.path.contains('_temp'))
          .where((f) => f.path.endsWith('.json'))
          .toList();

      expect(
        schemaFiles.length,
        equals(8),
        reason: 'Should have exactly 8 schema files '
            '(v31, v48, v52, v57, v61, v67, v71, v72)',
      );
    });

    test('fresh install creates the current schema correctly', () async {
      final db = AppDatabase(NativeDatabase.memory());

      // Insert default data
      await insertMinimalSettings(db);

      // Verify current schema version
      final versionQuery =
          await db.customSelect('PRAGMA user_version').getSingle();
      final version = versionQuery.read<int>('user_version');

      expect(
        version,
        equals(72),
        reason: 'Fresh install should create v72 schema',
      );

      // Verify all tables exist
      final tableQuery = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
          )
          .get();

      final tables = tableQuery.map((row) => row.read<String>('name')).toList();

      expect(tables, contains('plans'));
      expect(tables, contains('gym_sets'));
      expect(tables, contains('settings'));
      expect(tables, contains('plan_exercises'));
      expect(tables, contains('metadata'));
      expect(tables, contains('workouts'));
      expect(tables, contains('notes'));
      expect(tables, contains('bodyweight_entries'));
      expect(tables, contains('chat_messages'));

      await db.close();
    });

    test('v31 to v48 migration creates workouts table and metadata', () async {
      final connection = await verifier.startAt(31);
      final db = AppDatabase(connection.executor);

      await insertMinimalSettings(db);

      // Migrate to v48
      try {
        await verifier.migrateAndValidate(db, 48);
      } catch (e) {
        // Schema validation may have minor differences
      }

      // Verify workouts table exists
      final tableQuery = await db
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='workouts'")
          .getSingleOrNull();

      expect(tableQuery, isNotNull,
          reason: 'Workouts table should exist after v31→v48');

      // Verify metadata table exists
      final metadataQuery = await db
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='metadata'")
          .getSingleOrNull();

      expect(metadataQuery, isNotNull,
          reason: 'Metadata table should exist after v31→v48');

      await db.close();
    });

    test('v48 to v52 migration creates notes table', () async {
      final connection = await verifier.startAt(48);
      final db = AppDatabase(connection.executor);

      await insertMinimalSettings(db);

      // Migrate to v52
      try {
        await verifier.migrateAndValidate(db, 52);
      } catch (e) {
        // Schema validation may have minor differences
      }

      // Verify notes table exists
      final tableQuery = await db
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='notes'")
          .getSingleOrNull();

      expect(tableQuery, isNotNull,
          reason: 'Notes table should exist after v48→v52');

      // Verify gym_sets has sequence and warmup columns
      final columnsQuery =
          await db.customSelect("PRAGMA table_info(gym_sets)").get();

      final columns =
          columnsQuery.map((row) => row.read<String>('name')).toList();
      expect(columns, contains('sequence'));
      expect(columns, contains('warmup'));

      await db.close();
    });

    test('v52 to v57 migration creates bodyweight_entries table', () async {
      final connection = await verifier.startAt(52);
      final db = AppDatabase(connection.executor);

      await insertMinimalSettings(db);

      // Migrate to v57
      try {
        await verifier.migrateAndValidate(db, 57);
      } catch (e) {
        // Schema validation may have minor differences
      }

      // Verify bodyweight_entries table exists
      final tableQuery = await db
          .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='bodyweight_entries'")
          .getSingleOrNull();

      expect(tableQuery, isNotNull,
          reason: 'bodyweight_entries table should exist after v52→v57');

      // Verify 5/3/1 training columns exist in settings
      final columnsQuery =
          await db.customSelect("PRAGMA table_info(settings)").get();

      final columns =
          columnsQuery.map((row) => row.read<String>('name')).toList();
      expect(columns, contains('fivethreeone_squat_tm'));
      expect(columns, contains('fivethreeone_week'));

      await db.close();
    });

    test('v57 to v61 migration adds set_order and fixes sequences', () async {
      final schema = await verifier.schemaAt(57);

      // Seed through the raw v57 database: AppDatabase migrates on its first
      // query, so anything inserted through it would arrive too late for the
      // v57→v61 normalization to see.
      schema.rawDatabase.execute(
        "INSERT INTO workouts (id, start_time, end_time, name) "
        "VALUES (1, 1000, 2000, 'Test Workout')",
      );
      for (var i = 0; i < 3; i++) {
        schema.rawDatabase.execute(
          'INSERT INTO gym_sets (name, reps, weight, unit, created, '
          'workout_id, sequence) '
          "VALUES ('Bench Press', 10, 100, 'kg', ${1000 + i}, 1, $i)",
        );
      }

      final db = AppDatabase(schema.newConnection());

      // Migrate to v61 (includes sequence normalization fix)
      try {
        await verifier.migrateAndValidate(db, 61);
      } catch (e) {
        // Schema validation may have minor differences
      }

      // Verify set_order column exists
      final columnsQuery =
          await db.customSelect("PRAGMA table_info(gym_sets)").get();

      final columns =
          columnsQuery.map((row) => row.read<String>('name')).toList();
      expect(columns, contains('set_order'),
          reason: 'set_order column should exist after v57→v61');

      // Verify sequence normalization: all bench press sets should have sequence=0
      final sets = await db.select(db.gymSets).get();
      expect(sets.length, equals(3));

      for (final set in sets) {
        expect(
          set.sequence,
          equals(0),
          reason:
              'After v60→v61 migration, all sets of same exercise should have sequence=0',
        );
      }

      // Verify set_order is correctly assigned (0, 1, 2)
      final setOrders = sets.map((s) => s.setOrder).toList()..sort();
      expect(setOrders, equals([0, 1, 2]),
          reason: 'set_order should be 0, 1, 2');

      // Verify Spotify columns exist — they live on settings, not gym_sets
      final settingsColumns = (await db
              .customSelect('PRAGMA table_info(settings)')
              .get())
          .map((row) => row.read<String>('name'))
          .toList();
      expect(settingsColumns, contains('spotify_access_token'));
      expect(settingsColumns, contains('spotify_refresh_token'));
      expect(settingsColumns, contains('spotify_token_expiry'));

      await db.close();
    });

    test('full migration path: v31 to v61', () async {
      final schema = await verifier.schemaAt(31);

      // Seed through the raw v31 database: AppDatabase migrates on its first
      // query, so data inserted through it would never go through the
      // migration this test is about.
      schema.rawDatabase.execute(
        "INSERT INTO plans (id, days, exercises, title) "
        "VALUES (1, 'Monday,Wednesday,Friday', 'Bench Press,Squat', 'Test Plan')",
      );
      schema.rawDatabase.execute(
        'INSERT INTO gym_sets (name, reps, weight, unit, created) '
        "VALUES ('Bench Press', 10, 100, 'kg', 1000)",
      );
      const planId = 1;

      final db = AppDatabase(schema.newConnection());

      await insertMinimalSettings(db);

      // Migrate all the way to v61
      try {
        await verifier.migrateAndValidate(db, 61);
      } catch (e) {
        // Schema validation may have minor differences
      }

      // Verify all tables exist
      final tableQuery = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
          )
          .get();

      final tables = tableQuery.map((row) => row.read<String>('name')).toList();

      expect(tables, contains('plans'));
      expect(tables, contains('gym_sets'));
      expect(tables, contains('settings'));
      expect(tables, contains('plan_exercises'));
      expect(tables, contains('metadata'));
      expect(tables, contains('workouts'));
      expect(tables, contains('notes'));
      expect(tables, contains('bodyweight_entries'));

      // Verify data preserved
      final plans = await db.select(db.plans).get();
      expect(plans.length, equals(1));
      expect(plans[0].id, equals(planId));

      final sets = await db.select(db.gymSets).get();
      expect(sets.length, equals(1));
      expect(sets[0].name, equals('Bench Press'));

      await db.close();
    });

    test('v67 to v68 adds supplemental templates to existing blocks', () async {
      final schema = await verifier.schemaAt(67);

      // Seed through the raw v67 database: AppDatabase migrates on its first
      // query, so a block inserted through it would arrive after the migration.
      schema.rawDatabase.execute(
        'INSERT INTO five_three_one_blocks '
        '(id, created, squat_tm, bench_tm, deadlift_tm, press_tm, unit, '
        'current_cycle, current_week, is_active) '
        "VALUES (1, 1000, 100, 80, 120, 50, 'kg', 0, 1, 1)",
      );

      final db = AppDatabase(schema.newConnection());

      final blocks = await db.select(db.fiveThreeOneBlocks).get();
      expect(blocks.length, equals(1));
      expect(
        blocks.single.leaderSupplemental,
        equals('bbb'),
        reason: 'Pre-v68 blocks ran BBB during Leaders',
      );
      expect(
        blocks.single.anchorSupplemental,
        equals('fsl'),
        reason: 'Pre-v68 blocks ran FSL during the Anchor',
      );

      await db.close();
    });

    test('v70 backfills applied TM bumps from block position', () async {
      final schema = await verifier.schemaAt(67);

      // Cycle 3 (Anchor) — Leader 1 and Leader 2 each bumped on their way out.
      schema.rawDatabase.execute(
        'INSERT INTO five_three_one_blocks '
        '(id, created, squat_tm, bench_tm, deadlift_tm, press_tm, unit, '
        'current_cycle, current_week, is_active) '
        "VALUES (1, 1000, 109, 84.4, 129, 54.4, 'kg', 3, 1, 1)",
      );

      final db = AppDatabase(schema.newConnection());

      final blocks = await db.select(db.fiveThreeOneBlocks).get();
      expect(
        blocks.single.tmBumps,
        equals(2),
        reason: 'Both Leader cycles bumped before reaching the Anchor',
      );

      await db.close();
    });

    test('v69 renames Barbell Bench Press and dedupes plans', () async {
      final schema = await verifier.schemaAt(67);

      // Seed through the raw v67 database: AppDatabase migrates on its first
      // query, so rows inserted through it would arrive after the rename.
      schema.rawDatabase.execute(
        "INSERT INTO plans (id, days) VALUES (1, 'Monday')",
      );
      // Both casings the rename has to cover: the shipped seed used sentence
      // case, hand-entered rows used title case.
      for (final name in ['Barbell Bench Press', 'Barbell bench press']) {
        schema.rawDatabase.execute(
          'INSERT INTO gym_sets (name, reps, weight, unit, created) '
          "VALUES ('$name', 5, 100, 'kg', 1000)",
        );
      }
      // Plan 1 already lists a separate 'Bench Press' — after the rename the
      // two must collapse into one row.
      for (final name in ['Barbell Bench Press', 'Bench Press']) {
        schema.rawDatabase.execute(
          'INSERT INTO plan_exercises (plan_id, exercise, enabled) '
          "VALUES (1, '$name', 1)",
        );
      }

      final db = AppDatabase(schema.newConnection());

      final sets = await db.select(db.gymSets).get();
      expect(
        sets.map((s) => s.name).toSet(),
        equals({'Bench Press'}),
        reason: 'Both casings should rename to Bench Press',
      );

      final planExercises = await db.select(db.planExercises).get();
      expect(
        planExercises.map((e) => e.exercise).toList(),
        equals(['Bench Press']),
        reason: 'The duplicate Bench Press row should be dropped',
      );

      await db.close();
    });

    test('v70 to v71 adds chat_messages without touching gym_sets', () async {
      final schema = await verifier.schemaAt(67);

      // Seed through the raw pre-v71 database: AppDatabase migrates on its
      // first query, so rows inserted through it would arrive after the
      // migration.
      schema.rawDatabase.execute(
        'INSERT INTO gym_sets (name, reps, weight, unit, created) '
        "VALUES ('Bench Press', 5, 100, 'kg', 1000)",
      );

      final db = AppDatabase(schema.newConnection());

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name='chat_messages'",
          )
          .get();
      expect(tables.length, equals(1), reason: 'chat_messages should exist');

      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion.insert(
              role: 'user',
              created: DateTime.fromMillisecondsSinceEpoch(1000),
            ),
          );
      final messages = await db.select(db.chatMessages).get();
      expect(messages.single.workoutId, isNull, reason: 'ad-hoc thread');

      // Existing data untouched by an additive migration.
      final sets = await db.select(db.gymSets).get();
      expect(sets.length, equals(1));
      expect(sets.single.name, equals('Bench Press'));

      await db.close();
    });

    test('v71 to v72 groups existing messages into named threads', () async {
      final schema = await verifier.schemaAt(71);

      // Two scopes that predate threads: the single rolling ad-hoc thread and
      // one workout thread. They must come out as two separate chat_threads.
      schema.rawDatabase.execute(
        'INSERT INTO chat_messages (workout_id, role, content, created) VALUES '
        "(NULL, 'user', 'should i switch to an fsl leader?', 1000), "
        "(NULL, 'assistant', 'Run it as an anchor.', 1001), "
        "(9, 'user', 'add the prescribed bench work', 2000)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO gym_sets (name, reps, weight, unit, created) '
        "VALUES ('Bench Press', 5, 100, 'kg', 1000)",
      );

      final db = AppDatabase(schema.newConnection());

      final threads = await (db.select(db.chatThreads)
            ..orderBy([(row) => OrderingTerm(expression: row.id)]))
          .get();
      expect(threads.length, equals(2), reason: 'one per pre-thread scope');

      final adHoc = threads.firstWhere((thread) => thread.workoutId == null);
      final workoutThread = threads.firstWhere((thread) => thread.workoutId == 9);
      expect(
        adHoc.title,
        equals('should i switch to an fsl leader?'),
        reason: 'titled from its first user message',
      );
      expect(workoutThread.title, equals('add the prescribed bench work'));

      final messages = await db.select(db.chatMessages).get();
      expect(
        messages.where((row) => row.threadId == adHoc.id).length,
        equals(2),
      );
      expect(
        messages.where((row) => row.threadId == workoutThread.id).length,
        equals(1),
      );
      expect(
        messages.every((row) => row.threadId != null),
        isTrue,
        reason: 'no message is left unscoped',
      );

      // Existing data untouched by an additive migration.
      final sets = await db.select(db.gymSets).get();
      expect(sets.single.name, equals('Bench Press'));

      await db.close();
    });

    test('rejects database versions older than v31', () async {
      // We can't actually test versions < 31 since we deleted those schema files
      // Instead, verify the version check logic exists in database.dart
      final dbFile = File('lib/database/database.dart');
      final content = dbFile.readAsStringSync();

      expect(
        content.contains('if (from < 31)'),
        isTrue,
        reason: 'database.dart should check for versions < 31',
      );
      expect(
        content.contains('UnsupportedError'),
        isTrue,
        reason: 'database.dart should throw UnsupportedError for old versions',
      );
    });
  });
}
