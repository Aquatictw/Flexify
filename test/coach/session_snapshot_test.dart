import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/coach/session_snapshot.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/fivethreeone/schemes.dart';

import '../test_helpers.dart';

typedef _Seed = Future<void> Function(AppDatabase database);

const _vocabulary = [
  'Bench Press',
  'Squat',
  'Deadlift',
  'Overhead Press',
  'Lat Pulldown',
  'Barbell Row',
  'Dumbbell Curl',
  'Triceps Pushdown',
  'Leg Press',
  'Face Pull',
  'Chin Up',
  'Incline Bench Press',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    database = await createTestDatabase();

    // A fresh AppDatabase seeds the default exercise catalogue
    // (`defaultSets`/`defaultPlans`/`defaultPlanExercises` in
    // lib/database/defaults.dart) from `onCreate`. Those rows are hidden but
    // not tombstones, so they legitimately flow into `exerciseVocabulary` and
    // would swamp the twelve names each fixture describes. The fixtures model a
    // database whose only exercises are the ones they name, so clear the
    // catalogue and let each case seed its own state from scratch.
    await database.delete(database.gymSets).go();
    await database.delete(database.planExercises).go();
    await database.delete(database.plans).go();
  });

  tearDown(() async {
    await database.close();
  });

  final leader2 = _block(
    cycle: 1,
    week: 2,
    tmBumps: 1,
  );
  final cases = <_FixtureCase>[
    _FixtureCase(
      name: 'leader2-w2-kg',
      block: leader2,
      workout: _workout(412, planId: 1412),
      unit: 'kg',
      seed: (database) async {
        await _seedPlan(database, 1412, ['Bench Press']);
        await _seedHistory(
          database,
          'Bench Press',
          const [(5, 65), (5, 75), (8, 85)],
        );
        // Tombstones from a deleted set must not create a workout exercise.
        await _insertSet(
          database,
          name: 'Bench Press',
          reps: -1,
          weight: 90,
          sequence: -1,
          workoutId: 412,
          created: DateTime(2026, 7, 23, 12),
        );
      },
    ),
    _FixtureCase(
      name: 'anchor-w3-kg',
      block: _block(cycle: 3, week: 3, tmBumps: 2),
      workout: _workout(540, planId: 1540),
      unit: 'kg',
      seed: (database) async {
        await _seedPlan(database, 1540, ['Bench Press']);
        await _seedHistory(
          database,
          'Bench Press',
          const [(5, 70), (3, 80), (7, 90)],
        );
      },
    ),
    _FixtureCase(
      name: 'deload-kg',
      block: _block(cycle: 2, week: 1, tmBumps: 2),
      workout: _workout(520, planId: 1520),
      unit: 'kg',
      seed: (database) => _seedPlan(database, 1520, ['Squat']),
    ),
    _FixtureCase(
      name: 'tmtest-kg',
      block: _block(cycle: 4, week: 1, tmBumps: 3),
      workout: _workout(530, planId: 1530),
      unit: 'kg',
      seed: (database) => _seedPlan(database, 1530, ['Squat']),
    ),
    _FixtureCase(
      name: 'leader1-w1-lb',
      block: _block(
        cycle: 0,
        week: 1,
        tmBumps: 0,
        unit: 'lb',
        squatTm: 315,
        benchTm: 225,
        deadliftTm: 405,
        pressTm: 145,
        leaderSupplemental: supplementalFsl,
      ),
      workout: _workout(501, planId: 1501),
      unit: 'lb',
      seed: (database) async {
        await _seedPlan(database, 1501, ['Bench Press']);
        await _seedHistory(
          database,
          'Bench Press',
          const [(5, 140), (5, 165), (8, 185)],
          unit: 'lb',
        );
      },
    ),
    _FixtureCase(
      name: 'accessory-history-kg',
      block: leader2,
      workout: _workout(570, planId: 1570),
      unit: 'kg',
      seed: (database) async {
        await _seedPlan(database, 1570, ['Lat Pulldown']);
        await _seedWorkoutSets(
          database,
          workoutId: 570,
          name: 'Bench Press',
          sets: const [(5, 70, false), (5, 80, false), (5, 90, false)],
        );
        await _seedHistory(
          database,
          'Bench Press',
          const [(5, 65), (5, 75), (8, 85)],
        );
        await _seedHistory(
          database,
          'Lat Pulldown',
          const [(10, 55), (10, 55), (10, 55)],
        );
      },
    ),
    _FixtureCase(
      name: 'leader2-w2-kg-bench-present',
      block: leader2,
      workout: _workout(413),
      unit: 'kg',
      seed: (database) async {
        await _seedWorkoutSets(
          database,
          workoutId: 413,
          name: 'Bench Press',
          sets: const [(5, 70, false), (5, 80, false), (5, 90, true)],
        );
        await _seedHistory(
          database,
          'Bench Press',
          const [(5, 65), (5, 75), (8, 85)],
        );
      },
    ),
    _FixtureCase(
      name: 'leader2-w2-kg-bbb-present',
      block: leader2,
      workout: _workout(414),
      unit: 'kg',
      seed: (database) async {
        await _seedWorkoutSets(
          database,
          workoutId: 414,
          name: 'Bench Press',
          sets: const [
            (5, 70, false),
            (5, 80, false),
            (5, 90, false),
            (10, 60, true),
            (10, 60, true),
            (10, 60, true),
            (10, 60, true),
            (10, 60, true),
          ],
        );
        await _seedHistory(
          database,
          'Bench Press',
          const [(5, 65), (5, 75), (8, 85)],
        );
      },
    ),
    _FixtureCase(
      name: 'no-block-kg',
      block: null,
      workout: _workout(560),
      unit: 'kg',
      seed: (database) async {
        await _seedWorkoutSets(
          database,
          workoutId: 560,
          name: 'Lat Pulldown',
          sets: const [(10, 60, false), (10, 60, false), (10, 60, false)],
        );
        await _seedHistory(
          database,
          'Lat Pulldown',
          const [(10, 60), (10, 60), (10, 60)],
        );
      },
    ),
    _FixtureCase(
      name: 'no-workout-kg',
      block: leader2,
      workout: null,
      unit: 'kg',
      seed: (_) async {},
    ),
  ];

  for (final fixture in cases) {
    test(fixture.name, () async {
      await _seedVocabulary(database);
      await fixture.seed(database);

      final actual = await buildSessionSnapshot(
        block: fixture.block,
        workout: fixture.workout,
        unit: fixture.unit,
      );
      final decoded = jsonDecode(
        File(
          'server/test/coach_eval/snapshots/${fixture.name}.json',
        ).readAsStringSync(),
      ) as Map<String, Object?>;

      // `exerciseVocabulary` is compared as content rather than order. The
      // fixtures were hand-authored and list the twelve names in the order
      // someone typed them, which is not a use ordering: `accessory-history-kg`
      // puts three never-performed lifts between two performed ones, an order
      // no usage-based ranking can produce. Ordering is covered on its own
      // terms by the `exerciseVocabulary ordering` group below.
      expect(
        actual['exerciseVocabulary'],
        unorderedEquals(decoded['exerciseVocabulary']! as List<Object?>),
      );
      expect(
        encodeSessionSnapshot(_withoutVocabulary(actual)),
        encodeSessionSnapshot(_withoutVocabulary(decoded)),
      );
    });
  }

  group('exerciseVocabulary ordering', () {
    test('a performed lift outranks the seeded default catalogue', () async {
      // Rebuild the install-time catalogue this suite's setUp clears: hidden
      // rows, stamped now, for exercises the user has never performed.
      final installedAt = DateTime.now();
      for (final name in ['Arnold press', 'Roman chair leg raise', 'Crunch']) {
        await _insertSet(
          database,
          name: name,
          reps: 0,
          weight: 0,
          hidden: true,
          created: installedAt,
        );
      }
      // Performed a year before the install stamp, so plain MAX(created)
      // ordering would bury it behind all three defaults.
      await _seedHistory(database, 'Bench Press', const [(5, 100)]);

      final snapshot = await buildSessionSnapshot(
        block: null,
        workout: null,
        unit: 'kg',
      );

      expect(
        snapshot['exerciseVocabulary'],
        ['Bench Press', 'Arnold press', 'Crunch', 'Roman chair leg raise'],
      );
    });

    test('performed lifts rank most-recent-first', () async {
      await _insertSet(
        database,
        name: 'Squat',
        reps: 5,
        weight: 100,
        created: DateTime(2026, 7, 20, 12),
      );
      await _insertSet(
        database,
        name: 'Deadlift',
        reps: 5,
        weight: 140,
        created: DateTime(2026, 7, 22, 12),
      );
      await _insertSet(
        database,
        name: 'Overhead Press',
        reps: 5,
        weight: 50,
        created: DateTime(2026, 7, 21, 12),
      );

      final snapshot = await buildSessionSnapshot(
        block: null,
        workout: null,
        unit: 'kg',
      );

      expect(
        snapshot['exerciseVocabulary'],
        ['Deadlift', 'Overhead Press', 'Squat'],
      );
    });

    test('the cap never evicts a used exercise for a default', () async {
      for (var index = 0; index < 40; index++) {
        await _insertSet(
          database,
          name: 'Default $index',
          reps: 0,
          weight: 0,
          hidden: true,
          created: DateTime.now(),
        );
      }
      await _seedHistory(database, 'Bench Press', const [(5, 100)]);

      final snapshot = await buildSessionSnapshot(
        block: null,
        workout: null,
        unit: 'kg',
        vocabularyLimit: 3,
      );

      final vocabulary = snapshot['exerciseVocabulary']! as List<Object?>;
      expect(vocabulary, hasLength(3));
      expect(vocabulary.first, 'Bench Press');
    });

    test('tombstones never enter the vocabulary', () async {
      await _insertSet(
        database,
        name: 'Ghost Lift',
        reps: -1,
        weight: 0,
        sequence: -1,
        hidden: true,
        created: DateTime.now(),
      );

      final snapshot = await buildSessionSnapshot(
        block: null,
        workout: null,
        unit: 'kg',
      );

      expect(snapshot['exerciseVocabulary'], isEmpty);
    });
  });
}

Map<String, Object?> _withoutVocabulary(Map<String, Object?> snapshot) {
  return {...snapshot}..remove('exerciseVocabulary');
}

class _FixtureCase {
  const _FixtureCase({
    required this.name,
    required this.seed,
    required this.block,
    required this.workout,
    required this.unit,
  });

  final String name;
  final _Seed seed;
  final FiveThreeOneBlock? block;
  final Workout? workout;
  final String unit;
}

FiveThreeOneBlock _block({
  required int cycle,
  required int week,
  required int tmBumps,
  String unit = 'kg',
  double squatTm = 140,
  double benchTm = 100,
  double deadliftTm = 180,
  double pressTm = 65,
  String leaderSupplemental = supplementalBbb,
}) {
  return FiveThreeOneBlock(
    id: cycle + 1,
    created: DateTime(2026),
    squatTm: squatTm,
    benchTm: benchTm,
    deadliftTm: deadliftTm,
    pressTm: pressTm,
    unit: unit,
    currentCycle: cycle,
    currentWeek: week,
    isActive: true,
    leaderSupplemental: leaderSupplemental,
    anchorSupplemental: supplementalFsl,
    tmBumps: tmBumps,
  );
}

Workout _workout(int id, {int? planId}) {
  return Workout(
    id: id,
    startTime: DateTime(2026, 7, 23, 12),
    planId: planId,
  );
}

/// Puts the twelve fixture names in the database as never-performed entries,
/// the way the seeded default catalogue arrives on a fresh install. They must
/// stay hidden: a performed row here would be eligible history and would
/// contaminate `recent` for any name the fixture's session touches.
Future<void> _seedVocabulary(AppDatabase database) async {
  for (var index = 0; index < _vocabulary.length; index++) {
    await _insertSet(
      database,
      name: _vocabulary[index],
      reps: 1,
      weight: 0,
      hidden: true,
      setOrder: index,
      created: DateTime(2026, 7, 23, 23, 59).subtract(
        Duration(minutes: index),
      ),
    );
  }
}

Future<void> _seedPlan(
  AppDatabase database,
  int planId,
  List<String> exercises,
) async {
  await database.into(database.plans).insert(
        PlansCompanion.insert(
          id: Value(planId),
          days: '[]',
        ),
      );
  for (var index = 0; index < exercises.length; index++) {
    await database.into(database.planExercises).insert(
          PlanExercisesCompanion.insert(
            enabled: true,
            exercise: exercises[index],
            planId: planId,
            sequence: Value(index),
          ),
        );
  }
}

Future<void> _seedWorkoutSets(
  AppDatabase database, {
  required int workoutId,
  required String name,
  required List<(num reps, num weight, bool hidden)> sets,
}) async {
  for (var index = 0; index < sets.length; index++) {
    final set = sets[index];
    await _insertSet(
      database,
      name: name,
      reps: set.$1.toDouble(),
      weight: set.$2.toDouble(),
      hidden: set.$3,
      workoutId: workoutId,
      setOrder: index,
      created: DateTime(2026, 7, 23, 12).add(Duration(minutes: index)),
    );
  }
}

Future<void> _seedHistory(
  AppDatabase database,
  String name,
  List<(num reps, num weight)> sets, {
  String unit = 'kg',
}) async {
  for (var index = 0; index < sets.length; index++) {
    final set = sets[index];
    await _insertSet(
      database,
      name: name,
      reps: set.$1.toDouble(),
      weight: set.$2.toDouble(),
      unit: unit,
      setOrder: index,
      created: DateTime(2026, 7, 22, 12).add(Duration(minutes: index)),
    );
  }
}

Future<void> _insertSet(
  AppDatabase database, {
  required String name,
  required double reps,
  required double weight,
  required DateTime created,
  String unit = 'kg',
  bool hidden = false,
  int sequence = 0,
  int? setOrder,
  int? workoutId,
}) {
  return database.into(database.gymSets).insert(
        GymSetsCompanion.insert(
          name: name,
          reps: reps,
          weight: weight,
          unit: unit,
          created: created,
          hidden: Value(hidden),
          sequence: Value(sequence),
          setOrder: Value(setOrder),
          workoutId: Value(workoutId),
        ),
      );
}
