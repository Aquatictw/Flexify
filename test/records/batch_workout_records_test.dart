import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/main.dart' as app;
import 'package:jackedlog/records/records_service.dart';

import '../test_helpers.dart';

/// Counts SELECTs so the History engine's query count can be asserted to be
/// bounded rather than proportional to the number of distinct exercise names.
class _SelectCounter extends QueryInterceptor {
  int count = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    count++;
    return executor.runSelect(statement, args);
  }
}

/// The pre-optimization record engine, kept verbatim as an oracle: per
/// exercise, one MAX query plus a full-history scan to find the earliest set
/// holding each best. The optimized engine must agree with it exactly.
Future<Map<int, Map<int, Set<RecordType>>>> referenceRecords(
  AppDatabase db,
  List<int> workoutIds,
) async {
  final out = <int, Map<int, Set<RecordType>>>{};

  final workoutSets = await (db.gymSets.select()
        ..where(
          (s) =>
              s.workoutId.isIn(workoutIds) &
              s.hidden.equals(false) &
              s.warmup.equals(false) &
              s.cardio.equals(false),
        ))
      .get();

  for (final name in workoutSets.map((s) => s.name).toSet()) {
    final result = await db.customSelect(
      '''
      SELECT
        MAX(weight) as best_weight,
        MAX(CASE WHEN weight >= 0 THEN weight / (1.0278 - 0.0278 * reps) ELSE weight * (1.0278 - 0.0278 * reps) END) as best_1rm,
        MAX(weight * reps) as best_volume
      FROM gym_sets
      WHERE name = ? AND hidden = 0 AND warmup = 0 AND cardio = 0
      ''',
      variables: [Variable.withString(name)],
    ).getSingleOrNull();
    if (result == null) continue;

    final bestWeight = result.read<double?>('best_weight') ?? 0.0;
    final best1RM = result.read<double?>('best_1rm') ?? 0.0;
    final bestVolume = result.read<double?>('best_volume') ?? 0.0;

    final allSets = await (db.gymSets.select()
          ..where(
            (s) =>
                s.name.equals(name) &
                s.hidden.equals(false) &
                s.warmup.equals(false) &
                s.cardio.equals(false),
          ))
        .get();

    int? minWeightId;
    int? minRmId;
    int? minVolumeId;
    for (final set in allSets) {
      if (set.weight == bestWeight && bestWeight > 0) {
        minWeightId =
            minWeightId == null || set.id < minWeightId ? set.id : minWeightId;
      }
      if (calculate1RM(set.weight, set.reps) == best1RM && best1RM > 0) {
        minRmId = minRmId == null || set.id < minRmId ? set.id : minRmId;
      }
      if (calculateVolume(set.weight, set.reps) == bestVolume &&
          bestVolume > 0) {
        minVolumeId =
            minVolumeId == null || set.id < minVolumeId ? set.id : minVolumeId;
      }
    }

    for (final set in workoutSets.where((s) => s.name == name)) {
      if (set.workoutId == null) continue;
      final types = <RecordType>{};
      if (set.weight == bestWeight && set.id == minWeightId) {
        types.add(RecordType.bestWeight);
      }
      if (calculate1RM(set.weight, set.reps) == best1RM && set.id == minRmId) {
        types.add(RecordType.best1RM);
      }
      if (calculateVolume(set.weight, set.reps) == bestVolume &&
          set.id == minVolumeId) {
        types.add(RecordType.bestVolume);
      }
      if (types.isNotEmpty) {
        (out[set.workoutId!] ??= {})[set.id] = types;
      }
    }
  }

  final cardioWorkoutSets = await (db.gymSets.select()
        ..where(
          (s) =>
              s.workoutId.isIn(workoutIds) &
              s.hidden.equals(false) &
              s.warmup.equals(false) &
              s.cardio.equals(true),
        ))
      .get();

  for (final name in cardioWorkoutSets.map((s) => s.name).toSet()) {
    final history = await (db.gymSets.select()
          ..where(
            (s) =>
                s.name.equals(name) &
                s.hidden.equals(false) &
                s.warmup.equals(false) &
                s.cardio.equals(true),
          ))
        .get();

    for (final set in cardioWorkoutSets.where((s) => s.name == name)) {
      if (set.workoutId == null) continue;
      final types = calculateCardioRecords(
        set,
        history.where((other) => other.id != set.id),
      );
      if (types.isNotEmpty) (out[set.workoutId!] ??= {})[set.id] = types;
    }
  }

  return out;
}

void main() {
  late AppDatabase testDb;
  late _SelectCounter counter;
  late List<int> workoutIds;

  /// Fixture covering best weight, 1RM, volume, every cardio metric, ties,
  /// hidden sets, warmups, multiple workouts and multiple bouts.
  Future<void> seed() async {
    final w1 = await testDb.workouts.insertOne(createTestWorkout());
    final w2 = await testDb.workouts.insertOne(createTestWorkout());
    final w3 = await testDb.workouts.insertOne(createTestWorkout());
    workoutIds = [w1, w2, w3];

    Future<void> add(
      int workout,
      String name, {
      double weight = 0,
      double reps = 0,
      bool warmup = false,
      bool hidden = false,
      bool cardio = false,
      double duration = 0,
      double distance = 0,
      int? incline,
    }) async {
      await testDb.gymSets.insertOne(
        GymSetsCompanion.insert(
          name: name,
          reps: reps,
          weight: weight,
          unit: cardio ? 'km' : 'kg',
          created: DateTime.now(),
          workoutId: Value(workout),
          warmup: Value(warmup),
          hidden: Value(hidden),
          cardio: Value(cardio),
          duration: Value(duration),
          distance: Value(distance),
          incline: Value(incline),
        ),
      );
    }

    // Strength: rising weight, a volume best that isn't the weight best, and
    // a single-rep set (1RM edge).
    await add(w1, 'Bench Press', weight: 100, reps: 5, warmup: true);
    await add(w1, 'Bench Press', weight: 100, reps: 5);
    await add(w1, 'Bench Press', weight: 60, reps: 20); // best volume
    await add(w2, 'Bench Press', weight: 120, reps: 3); // best weight + 1RM
    await add(w2, 'Bench Press', weight: 200, reps: 5, hidden: true);
    await add(w3, 'Bench Press', weight: 140, reps: 1); // single rep

    // Ties: two identical sets across workouts — earliest id must win.
    await add(w1, 'Squat', weight: 150, reps: 5);
    await add(w2, 'Squat', weight: 150, reps: 5);
    await add(w3, 'Squat', weight: 150, reps: 5);

    // Assisted (negative weight) exercise.
    await add(w1, 'Assisted Pullup', weight: -20, reps: 8);
    await add(w2, 'Assisted Pullup', weight: -10, reps: 8);

    // Exercise whose only sets are excluded.
    await add(w1, 'Cable Fly', weight: 30, reps: 12, warmup: true);
    await add(w2, 'Cable Fly', weight: 40, reps: 12, hidden: true);

    // Cardio: multiple bouts per workout, each metric peaking on a
    // different bout, plus warmup/hidden exclusions.
    await add(w1, 'Treadmill',
        cardio: true, duration: 30, distance: 5, incline: 2);
    await add(w1, 'Treadmill',
        cardio: true, duration: 10, distance: 3, incline: 8); // speed + incline
    await add(w2, 'Treadmill',
        cardio: true, duration: 45, distance: 6, incline: 1); // duration + dist
    await add(w2, 'Treadmill',
        cardio: true, duration: 90, distance: 20, incline: 20, warmup: true);
    await add(w3, 'Treadmill',
        cardio: true, duration: 45, distance: 6, incline: 1); // ties w2

    // Cardio exercise with a single bout ever (first-bout branch).
    await add(w3, 'Rower', cardio: true, duration: 12, distance: 3);
    // Cardio bout with no distance at all.
    await add(w3, 'Stairmaster', cardio: true, duration: 0, incline: 5);
  }

  setUp(() async {
    counter = _SelectCounter();
    testDb = AppDatabase(NativeDatabase.memory().interceptWith(counter));
    app.db = testDb;
    clearPRCache();
    await seed();
  });

  tearDown(() async {
    await testDb.close();
  });

  test('matches the pre-optimization engine exactly', () async {
    final expected = await referenceRecords(testDb, workoutIds);
    clearPRCache();
    final actual = await getBatchWorkoutRecords(workoutIds);

    expect(actual.keys.toSet(), expected.keys.toSet());
    for (final workoutId in expected.keys) {
      expect(actual[workoutId], expected[workoutId],
          reason: 'workout $workoutId');
    }
  });

  test('getWorkoutRecords agrees with the batch engine per workout', () async {
    for (final workoutId in workoutIds) {
      clearPRCache();
      final single = await getWorkoutRecords(workoutId);
      final expected = (await referenceRecords(testDb, [workoutId]))[workoutId];
      expect(single, expected ?? <int, Set<RecordType>>{});
    }
  });

  test('records survive a growing exercise library without more queries',
      () async {
    // Baseline: three strength + three cardio exercises on the page.
    clearPRCache();
    counter.count = 0;
    await getBatchWorkoutRecords(workoutIds);
    final baseline = counter.count;

    // Add many more distinct exercises to the same workouts.
    for (var i = 0; i < 25; i++) {
      await testDb.gymSets.insertOne(
        createTestSet(workoutId: workoutIds[i % 3], name: 'Filler $i'),
      );
    }

    clearPRCache();
    counter.count = 0;
    await getBatchWorkoutRecords(workoutIds);

    // The old engine issued two queries per distinct name; the new one is flat.
    expect(counter.count, baseline);
    expect(counter.count, lessThanOrEqualTo(8));
  });

  test('excluded sets never hold records', () async {
    clearPRCache();
    final records = await getBatchWorkoutRecords(workoutIds);
    final flagged = records.values.expand((w) => w.keys).toSet();

    final excluded = await (testDb.gymSets.select()
          ..where((s) => s.hidden.equals(true) | s.warmup.equals(true)))
        .get();
    for (final set in excluded) {
      expect(flagged, isNot(contains(set.id)), reason: 'set ${set.id}');
    }
  });

  test('ties resolve to the earliest set', () async {
    clearPRCache();
    final records = await getBatchWorkoutRecords(workoutIds);
    // The seeded database ships hidden template rows; only real sets count.
    final squats = await (testDb.gymSets.select()
          ..where((s) => s.name.equals('Squat') & s.hidden.equals(false))
          ..orderBy([(s) => OrderingTerm(expression: s.id)]))
        .get();

    final flagged = records.values.expand((w) => w.keys).toSet();
    expect(flagged, contains(squats.first.id));
    for (final later in squats.skip(1)) {
      expect(flagged, isNot(contains(later.id)));
    }
  });
}
