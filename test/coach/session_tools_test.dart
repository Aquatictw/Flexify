import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/coach/session_tools.dart';
import 'package:jackedlog/database/database.dart';

import '../test_helpers.dart';

/// A Leader 2 block: week 2 of 5's PRO is 70/80/90% of the training max.
FiveThreeOneBlock buildBlock({
  String unit = 'kg',
  double benchTm = 100,
  int currentCycle = 1,
  int currentWeek = 2,
}) =>
    FiveThreeOneBlock(
      id: 1,
      created: DateTime.now(),
      squatTm: 140,
      benchTm: benchTm,
      deadliftTm: 180,
      pressTm: 60,
      unit: unit,
      currentCycle: currentCycle,
      currentWeek: currentWeek,
      isActive: true,
      leaderSupplemental: 'bbb',
      anchorSupplemental: 'fsl',
      tmBumps: 0,
    );

void main() {
  late AppDatabase database;

  setUp(() async {
    database = await createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  Future<Workout> startWorkout({int? planId}) async {
    return database.into(database.workouts).insertReturning(
          createTestWorkout(planId: planId),
        );
  }

  Future<GymSet> addSet({
    required String name,
    required int? workoutId,
    double weight = 100,
    double reps = 5,
    bool hidden = true,
    int sequence = 0,
    int? setOrder,
    String unit = 'kg',
    DateTime? created,
  }) async {
    return database.into(database.gymSets).insertReturning(
          GymSetsCompanion.insert(
            name: name,
            reps: reps,
            weight: weight,
            unit: unit,
            created: created ?? DateTime.now(),
            workoutId: Value(workoutId),
            sequence: Value(sequence),
            setOrder: Value(setOrder),
            hidden: Value(hidden),
          ),
        );
  }

  /// Rows for [name] in one workout. The database seeds a catalog row per
  /// default exercise (workout_id NULL), which is not session work.
  Future<List<GymSet>> setsFor(String name, int? workoutId) =>
      (database.select(database.gymSets)
        ..where(
          (row) => row.name.equals(name) & row.workoutId.equalsNullable(workoutId),
        )
        ..orderBy([
          (row) => OrderingTerm(expression: row.setOrder),
          (row) => OrderingTerm(expression: row.id),
        ]))
      .get();

  Future<Map<String, Object?>> apply(
    List<Map<String, Object?>> ops, {
    required Workout? workout,
    FiveThreeOneBlock? block,
    List<String> vocabulary = const <String>['Bench Press'],
    String settingsUnit = 'kg',
  }) =>
      applySessionChanges(
        arguments: <String, Object?>{'ops': ops},
        block: block,
        workout: workout,
        exerciseVocabulary: vocabulary,
        settingsUnit: settingsUnit,
      );

  group('prescribed-relative writes', () {
    test('"prescribed minus 5%" rewrites all three main sets in one '
        'transaction', () async {
      final workout = await startWorkout();
      for (var i = 0; i < 3; i++) {
        await addSet(
          name: 'Bench Press',
          workoutId: workout.id,
          weight: <double>[70, 80, 90][i],
          setOrder: i,
        );
      }

      // A single transaction dispatches exactly one table-update event on
      // commit, however many rows it touched.
      var notifications = 0;
      final subscription = database
          .tableUpdates(TableUpdateQuery.onTable(database.gymSets))
          .listen((_) => notifications++);

      final result = await apply(
        <Map<String, Object?>>[
          for (var i = 0; i < 3; i++)
            <String, Object?>{
              'op': 'edit_set',
              'exercise': 'Bench Press',
              'set_index': i,
              'weight_spec': <String, Object?>{'pct_of_prescribed': -0.05},
            },
        ],
        workout: workout,
        block: buildBlock(),
      );

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(result['ok'], isTrue);
      final rows = await setsFor('Bench Press', workout.id);
      expect(rows.map((row) => row.weight), <double>[67.5, 75, 85]);
      expect(rows.every((row) => row.hidden), isTrue);
      expect(notifications, 1);

      final applied = result['applied']! as List<Object?>;
      expect(
        (applied.first! as Map<String, Object?>)['set'],
        <String, Object?>{'weight': 67.5, 'reps': 5, 'unit': 'kg'},
      );
    });

    test('add_sets measures each new set against its resulting index',
        () async {
      final workout = await startWorkout();
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Bench Press',
            'sets': <Object?>[
              for (var i = 0; i < 3; i++)
                <String, Object?>{
                  'weight_spec': <String, Object?>{'pct_of_prescribed': 0},
                  'reps': 5,
                },
            ],
          },
        ],
        workout: workout,
        block: buildBlock(),
      );

      expect(result['ok'], isTrue);
      final rows = await setsFor('Bench Press', workout.id);
      expect(rows.map((row) => row.weight), <double>[70, 80, 90]);
      expect(rows.map((row) => row.setOrder), <int>[0, 1, 2]);
      expect(rows.every((row) => row.hidden), isTrue);
      expect(rows.every((row) => row.workoutId == workout.id), isTrue);
    });

    test('a set beyond the prescription returns an actionable error',
        () async {
      final workout = await startWorkout();
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Bench Press',
            'sets': <Object?>[
              for (var i = 0; i < 4; i++)
                <String, Object?>{
                  'weight_spec': <String, Object?>{'pct_of_prescribed': 0},
                  'reps': 5,
                },
            ],
          },
        ],
        workout: workout,
        block: buildBlock(),
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('no prescribed weight'));
      expect(await setsFor('Bench Press', workout.id), isEmpty);
    });
  });

  group('weight bases', () {
    test('pct_of_tm resolves against the block training max', () async {
      final workout = await startWorkout();
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Bench Press',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'pct_of_tm': 0.6},
                'reps': 10,
              },
            ],
          },
        ],
        workout: workout,
        block: buildBlock(),
      );

      expect(result['ok'], isTrue);
      final rows = await setsFor('Bench Press', workout.id);
      expect(rows.single.weight, 60);
      expect(rows.single.reps, 10);
    });

    test('pct_of_last_session resolves against the previous session',
        () async {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final previous = await startWorkout();
      await addSet(
        name: 'Lat Pulldown',
        workoutId: previous.id,
        weight: 60,
        hidden: false,
        created: lastWeek,
      );

      final workout = await startWorkout();
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Lat Pulldown',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'pct_of_last_session': -0.05},
                'reps': 10,
              },
            ],
          },
        ],
        workout: workout,
        vocabulary: <String>['Lat Pulldown'],
      );

      expect(result['ok'], isTrue, reason: '${result['error']}');
      final rows = await setsFor('Lat Pulldown', workout.id);
      expect(rows.last.workoutId, workout.id);
      expect(rows.last.weight, 57.5); // 57 -> nearest 2.5
    });

    test('pct_of_tm on an exercise with no training max is a tool error',
        () async {
      final workout = await startWorkout();
      await addSet(name: 'Lat Pulldown', workoutId: workout.id, weight: 60);

      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Lat Pulldown',
            'set_index': 0,
            'weight_spec': <String, Object?>{'pct_of_tm': 0.9},
          },
        ],
        workout: workout,
        block: buildBlock(),
        vocabulary: <String>['Lat Pulldown'],
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('has no training max'));
      expect((await setsFor('Lat Pulldown', workout.id)).single.weight, 60);
    });

    test('a percentage-point delta is rejected and writes nothing', () async {
      final workout = await startWorkout();
      for (var i = 0; i < 3; i++) {
        await addSet(
          name: 'Bench Press',
          workoutId: workout.id,
          weight: <double>[70, 80, 90][i],
          setOrder: i,
        );
      }

      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Bench Press',
            'set_index': 0,
            'weight_spec': <String, Object?>{'pct_of_prescribed': 0},
          },
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Bench Press',
            'set_index': 1,
            // 5% lighter written as percentage points: 500% lighter.
            'weight_spec': <String, Object?>{'pct_of_prescribed': -5},
          },
        ],
        workout: workout,
        block: buildBlock(),
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('signed fraction'));
      // The first op was valid; a later failure still writes nothing.
      final rows = await setsFor('Bench Press', workout.id);
      expect(rows.map((row) => row.weight), <double>[70, 80, 90]);
    });
  });

  group('unit inheritance', () {
    test('a main lift inherits the block unit, not the settings unit',
        () async {
      final workout = await startWorkout();
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Bench Press',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'pct_of_tm': 0.65},
                'reps': 5,
              },
            ],
          },
        ],
        workout: workout,
        block: buildBlock(unit: 'lb', benchTm: 225),
        // settingsUnit defaults to kg, which the block must override.
      );

      expect(result['ok'], isTrue);
      final row = (await setsFor('Bench Press', workout.id)).single;
      expect(row.unit, 'lb');
      // 146.25 rounds to the 5 lb increment, not the 2.5 kg one.
      expect(row.weight, 145);
    });

    test('an accessory inherits the unit of its most recent set', () async {
      final workout = await startWorkout();
      await addSet(
        name: 'Lat Pulldown',
        workoutId: null,
        hidden: false,
        unit: 'lb',
        created: DateTime.now().subtract(const Duration(days: 7)),
      );

      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Lat Pulldown',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 103},
                'reps': 10,
              },
            ],
          },
        ],
        workout: workout,
        // settingsUnit defaults to kg; the exercise's own history wins.
        vocabulary: <String>['Lat Pulldown'],
      );

      expect(result['ok'], isTrue);
      final rows = await setsFor('Lat Pulldown', workout.id);
      expect(rows.last.unit, 'lb');
      expect(rows.last.weight, 105);
    });

    test('an exercise with no history falls back to the settings unit',
        () async {
      final workout = await startWorkout();
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Lat Pulldown',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 103},
                'reps': 10,
              },
            ],
          },
        ],
        workout: workout,
        settingsUnit: 'lb',
        vocabulary: <String>['Lat Pulldown'],
      );

      expect(result['ok'], isTrue);
      final row = (await setsFor('Lat Pulldown', workout.id)).single;
      expect(row.unit, 'lb');
      expect(row.weight, 105);
    });
  });

  group('guard rails', () {
    test('an unknown exercise returns candidates and writes nothing', () async {
      final workout = await startWorkout();
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Bench',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 60},
                'reps': 5,
              },
            ],
          },
        ],
        workout: workout,
        vocabulary: <String>['Bench Press', 'Lat Pulldown'],
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains("unknown exercise 'Bench'"));
      expect(result['error'], contains('Bench Press'));
      expect(await setsFor('Bench', workout.id), isEmpty);
      expect(await setsFor('Bench Press', workout.id), isEmpty);
    });

    test('an index landing on a performed set is an error, not a no-op',
        () async {
      final workout = await startWorkout();
      await addSet(
        name: 'Bench Press',
        workoutId: workout.id,
        weight: 70,
        hidden: false,
        setOrder: 0,
      );
      await addSet(
        name: 'Bench Press',
        workoutId: workout.id,
        weight: 80,
        setOrder: 1,
      );

      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Bench Press',
            // 0 is the performed set: indices count every set, done included.
            'set_index': 0,
            'weight_spec': <String, Object?>{'absolute': 60},
          },
        ],
        workout: workout,
        block: buildBlock(),
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('already performed'));
      expect(result['error'], contains('propose_block_changes'));
      final rows = await setsFor('Bench Press', workout.id);
      expect(rows.map((row) => row.weight), <double>[70, 80]);
    });

    test('remove_sets refuses to delete a performed set', () async {
      final workout = await startWorkout();
      await addSet(
        name: 'Bench Press',
        workoutId: workout.id,
        hidden: false,
        setOrder: 0,
      );

      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'remove_sets',
            'exercise': 'Bench Press',
            'set_indices': <Object?>[0],
          },
        ],
        workout: workout,
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('already performed'));
      expect(await setsFor('Bench Press', workout.id), hasLength(1));
    });

    test('an out-of-range index is an error', () async {
      final workout = await startWorkout();
      await addSet(name: 'Bench Press', workoutId: workout.id, setOrder: 0);

      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Bench Press',
            'set_index': 3,
            'reps': 8,
          },
        ],
        workout: workout,
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('does not exist'));
    });

    test('sets in another workout are invisible to indexing', () async {
      final other = await startWorkout();
      await addSet(name: 'Bench Press', workoutId: other.id, setOrder: 0);
      await addSet(name: 'Bench Press', workoutId: other.id, setOrder: 1);

      final workout = await startWorkout();
      await addSet(
        name: 'Bench Press',
        workoutId: workout.id,
        weight: 90,
        setOrder: 0,
      );

      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Bench Press',
            'set_index': 1,
            'reps': 8,
          },
        ],
        workout: workout,
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('has 1 set(s) in this workout'));
    });

    test('create_new escalates to the confirm tier instead of writing',
        () async {
      final workout = await startWorkout();
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Zercher Squat',
            'create_new': true,
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 60},
                'reps': 5,
              },
            ],
          },
        ],
        workout: workout,
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('propose_block_changes'));
      expect(await setsFor('Zercher Squat', workout.id), isEmpty);
    });

    test('a unit or bare weight in an op is rejected', () async {
      final workout = await startWorkout();
      await addSet(name: 'Bench Press', workoutId: workout.id, setOrder: 0);

      final withUnit = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Bench Press',
            'set_index': 0,
            'weight_spec': <String, Object?>{'absolute': 60},
            'unit': 'kg',
          },
        ],
        workout: workout,
      );
      expect(withUnit['ok'], isFalse);
      expect(withUnit['error'], contains("does not take 'unit'"));

      final withWeight = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Bench Press',
            'set_index': 0,
            'weight': 60,
          },
        ],
        workout: workout,
      );
      expect(withWeight['ok'], isFalse);
      expect(withWeight['error'], contains("does not take 'weight'"));
      expect((await setsFor('Bench Press', workout.id)).single.weight, 100);
    });

    test('there is no write path without an active workout', () async {
      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Bench Press',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 60},
                'reps': 5,
              },
            ],
          },
        ],
        workout: null,
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('no active workout'));
      final written = await (database.select(database.gymSets)
            ..where((row) => row.workoutId.isNotNull()))
          .get();
      expect(written, isEmpty);
    });

    test('add_sets needs the exercise present and add_exercise needs it absent',
        () async {
      final workout = await startWorkout();
      final missing = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_sets',
            'exercise': 'Bench Press',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 60},
                'reps': 5,
              },
            ],
          },
        ],
        workout: workout,
      );
      expect(missing['ok'], isFalse);
      expect(missing['error'], contains('use add_exercise'));

      await addSet(name: 'Bench Press', workoutId: workout.id, setOrder: 0);
      final duplicate = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Bench Press',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 60},
                'reps': 5,
              },
            ],
          },
        ],
        workout: workout,
      );
      expect(duplicate['ok'], isFalse);
      expect(duplicate['error'], contains('use add_sets'));
    });
  });

  group('mixed ops', () {
    test('one call adds, edits and removes in a single transaction', () async {
      final workout = await startWorkout();
      await addSet(
        name: 'Bench Press',
        workoutId: workout.id,
        weight: 70,
        setOrder: 0,
      );
      await addSet(
        name: 'Bench Press',
        workoutId: workout.id,
        weight: 80,
        setOrder: 1,
      );

      var notifications = 0;
      final subscription = database
          .tableUpdates(TableUpdateQuery.onTable(database.gymSets))
          .listen((_) => notifications++);

      final result = await apply(
        <Map<String, Object?>>[
          <String, Object?>{
            'op': 'remove_sets',
            'exercise': 'Bench Press',
            'set_indices': <Object?>[0],
          },
          <String, Object?>{
            'op': 'edit_set',
            'exercise': 'Bench Press',
            'set_index': 0,
            'reps': 3,
          },
          <String, Object?>{
            'op': 'add_sets',
            'exercise': 'Bench Press',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 60},
                'reps': 10,
              },
            ],
          },
          <String, Object?>{
            'op': 'add_exercise',
            'exercise': 'Lat Pulldown',
            'sets': <Object?>[
              <String, Object?>{
                'weight_spec': <String, Object?>{'absolute': 41},
                'reps': 12,
                'amrap': true,
              },
            ],
          },
        ],
        workout: workout,
        vocabulary: <String>['Bench Press', 'Lat Pulldown'],
      );

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(result['ok'], isTrue, reason: '${result['error']}');
      expect(notifications, 1);

      final bench = await setsFor('Bench Press', workout.id);
      expect(bench.map((row) => row.weight), <double>[80, 60]);
      expect(bench.map((row) => row.reps), <double>[3, 10]);
      // The survivor closes the gap left by the removed set.
      expect(bench.map((row) => row.setOrder), <int>[0, 1]);

      final pulldown = (await setsFor('Lat Pulldown', workout.id)).single;
      expect(pulldown.weight, 40);
      expect(pulldown.sequence, 1); // appended after Bench Press
      expect(pulldown.hidden, isTrue);

      final applied = result['applied']! as List<Object?>;
      expect(applied, hasLength(4));
      expect(
        (applied.last! as Map<String, Object?>)['sets'],
        <Object?>[
          <String, Object?>{
            'weight': 40,
            'reps': 12,
            'unit': 'kg',
            'amrap': true,
          },
        ],
      );
    });
  });
}
