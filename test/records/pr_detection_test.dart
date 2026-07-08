import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/main.dart' as app;
import 'package:jackedlog/records/records_service.dart';

import '../test_helpers.dart';

void main() {
  late AppDatabase testDb;

  setUp(() async {
    testDb = await createTestDatabase();
    // Override the global db instance for testing
    app.db = testDb;
  });

  group('PR detection integration tests', () {
    test('detects new volume PR correctly', () async {
      // Insert existing sets for Bench Press
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Existing best: 100kg x 10 = 1000 volume
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Bench Press',
        ),
      );

      // New set: 80kg x 15 = 1200 volume (better!)
      final achievements = await checkForRecords(
        exerciseName: 'Bench Press',
        weight: 80,
        reps: 15,
        unit: 'kg',
        excludeSetId: null,
      );

      // Should detect volume PR
      expect(achievements.length, 1);
      expect(achievements.first.type, RecordType.bestVolume);
      expect(achievements.first.newValue, 1200.0);
      expect(achievements.first.previousValue, 1000.0);
      expect(achievements.first.unit, 'kg');
    });

    test('detects new weight PR correctly', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Existing best: 100kg x 10
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Squat',
        ),
      );

      // New heavier weight: 120kg x 5
      final achievements = await checkForRecords(
        exerciseName: 'Squat',
        weight: 120,
        reps: 5,
        unit: 'kg',
        excludeSetId: null,
      );

      // Should detect weight PR
      final weightPRs =
          achievements.where((a) => a.type == RecordType.bestWeight).toList();
      expect(weightPRs.length, 1);
      expect(weightPRs.first.newValue, 120.0);
      expect(weightPRs.first.previousValue, 100.0);
    });

    test('detects new 1RM PR correctly', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Existing: 100kg x 10 → 1RM ≈ 133.33kg
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Deadlift',
        ),
      );

      // New: 130kg x 5 → 1RM ≈ 146.38kg (better!)
      final achievements = await checkForRecords(
        exerciseName: 'Deadlift',
        weight: 130,
        reps: 5,
        unit: 'kg',
        excludeSetId: null,
      );

      // Should detect 1RM PR
      final rmPRs =
          achievements.where((a) => a.type == RecordType.best1RM).toList();
      expect(rmPRs.length, 1);
      expect(rmPRs.first.newValue, closeTo(146.26, 0.2));
      expect(rmPRs.first.previousValue, closeTo(133.33, 0.2));
    });

    test('detects multiple PR types in single set', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Existing: 100kg x 5
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Overhead Press',
          reps: 5,
        ),
      );

      // New: 140kg x 8 (beats weight, volume, AND 1RM)
      final achievements = await checkForRecords(
        exerciseName: 'Overhead Press',
        weight: 140,
        reps: 8,
        unit: 'kg',
        excludeSetId: null,
      );

      // Should detect all 3 PR types
      expect(achievements.length, 3);
      expect(achievements.map((a) => a.type).toSet(), {
        RecordType.bestWeight,
        RecordType.bestVolume,
        RecordType.best1RM,
      });
    });

    test('warmup sets ignored for PRs', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Insert warmup set with high numbers
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Bench Press',
          weight: 200,
          warmup: true, // This is a warmup set
        ),
      );

      // New working set: 150kg x 5 (lower than warmup)
      final achievements = await checkForRecords(
        exerciseName: 'Bench Press',
        weight: 150,
        reps: 5,
        unit: 'kg',
        excludeSetId: null,
      );

      // Should be treated as FIRST working set (warmup ignored)
      // So all 3 records should be detected
      expect(achievements.length, 3);
      expect(achievements.map((a) => a.type).toSet(), {
        RecordType.bestWeight,
        RecordType.bestVolume,
        RecordType.best1RM,
      });
    });

    test('cardio sets ignored for PRs', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Insert cardio set with high numbers
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Treadmill',
          reps: 30,
          cardio: true, // This is cardio
        ),
      );

      // New set: 80kg x 20 (lower than cardio)
      final achievements = await checkForRecords(
        exerciseName: 'Treadmill',
        weight: 80,
        reps: 20,
        unit: 'kg',
        excludeSetId: null,
      );

      // Should be treated as FIRST non-cardio set (cardio ignored)
      expect(achievements.length, 3);
    });

    test('detects cardio PRs independently', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Treadmill',
          unit: 'km',
          cardio: true,
          duration: 20,
          distance: 4,
          incline: 2,
        ),
      );

      final achievements = await checkForRecords(
        exerciseName: 'Treadmill',
        weight: 0,
        reps: 0,
        unit: 'km',
        cardio: true,
        duration: 30,
        distance: 7,
        incline: 4,
        excludeSetId: null,
      );

      expect(achievements.map((a) => a.type).toSet(), {
        RecordType.bestDuration,
        RecordType.bestDistance,
        RecordType.bestSpeed,
        RecordType.bestIncline,
      });
    });

    test('drop sets counted normally for PRs', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Insert drop set with good numbers
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Cable Fly',
          dropSet: true, // This is a drop set
        ),
      );

      // New set: 110kg x 5 (heavier weight)
      final achievements = await checkForRecords(
        exerciseName: 'Cable Fly',
        weight: 110,
        reps: 5,
        unit: 'kg',
        excludeSetId: null,
      );

      // Drop set should count - so only weight PR detected
      final weightPRs =
          achievements.where((a) => a.type == RecordType.bestWeight).toList();
      expect(weightPRs.length, 1);
      expect(weightPRs.first.newValue, 110.0);
      expect(weightPRs.first.previousValue, 100.0);
    });

    test('first set for exercise returns all PRs', () async {
      // No existing sets - brand new exercise
      final achievements = await checkForRecords(
        exerciseName: 'Romanian Deadlift',
        weight: 100,
        reps: 8,
        unit: 'kg',
        excludeSetId: null,
      );

      // First set = all records
      expect(achievements.length, 3);
      expect(achievements.map((a) => a.type).toSet(), {
        RecordType.bestWeight,
        RecordType.bestVolume,
        RecordType.best1RM,
      });

      // SQL aggregate functions (MAX) return a row even with no matches,
      // with NULL values that become 0.0 when read
      for (final achievement in achievements) {
        expect(achievement.previousValue, equals(0.0));
      }
    });

    test('hidden sets excluded from PR calculation', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Manually set hidden=true by creating a new companion with hidden field
      final hiddenSet = GymSetsCompanion.insert(
        name: 'Leg Press',
        reps: 20,
        weight: 300,
        unit: 'kg',
        created: DateTime.now(),
        hidden: const Value(true), // Hidden set
        workoutId: Value(workoutId),
        sequence: const Value(0),
      );
      await testDb.gymSets.insertOne(hiddenSet);

      // New set: 200kg x 10 (lower than hidden)
      final achievements = await checkForRecords(
        exerciseName: 'Leg Press',
        weight: 200,
        reps: 10,
        unit: 'kg',
        excludeSetId: null,
      );

      // Should be treated as FIRST non-hidden set (hidden ignored)
      expect(achievements.length, 3);
    });

    test('excludeSetId parameter excludes specific set from comparison',
        () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Insert a set
      final setId = await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Bench Press',
        ),
      );

      // Check for records with same values, excluding this set
      final achievements = await checkForRecords(
        exerciseName: 'Bench Press',
        weight: 100,
        reps: 10,
        unit: 'kg',
        excludeSetId: setId,
      );

      // Should detect all 3 PR types (excludeSetId works)
      // When there are rows but all excluded, MAX returns NULL which becomes 0.0
      // So previousValue will be 0.0, not null
      expect(achievements.length, 3);
      for (final achievement in achievements) {
        expect(achievement.previousValue, equals(0.0));
      }
    });
  });

  group('getSetRecords integration tests', () {
    test('identifies set with weight record', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Set 2: 120kg x 5 (weight PR)
      final set2Id = await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Squat',
          weight: 120,
          reps: 5,
        ),
      );

      final records = await getSetRecords(
        setId: set2Id,
        exerciseName: 'Squat',
        weight: 120,
        reps: 5,
      );

      expect(records, contains(RecordType.bestWeight));
    });

    test('identifies set with multiple records', () async {
      final workoutId = await testDb.workouts.insertOne(createTestWorkout());

      // Set 1: 100kg x 5
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Deadlift',
          reps: 5,
        ),
      );

      // Set 2: 140kg x 8 (beats all records)
      final set2Id = await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workoutId,
          name: 'Deadlift',
          weight: 140,
          reps: 8,
        ),
      );

      final records = await getSetRecords(
        setId: set2Id,
        exerciseName: 'Deadlift',
        weight: 140,
        reps: 8,
      );

      expect(records.length, 3);
      expect(records, contains(RecordType.bestWeight));
      expect(records, contains(RecordType.bestVolume));
      expect(records, contains(RecordType.best1RM));
    });
  });

  group('workoutHasRecords integration test', () {
    test('detects workout with record-breaking sets', () async {
      // Workout 1: baseline
      final workout1Id = await testDb.workouts.insertOne(
        createTestWorkout(
          name: 'Workout 1',
        ),
      );
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workout1Id,
          name: 'Bench Press',
        ),
      );

      // Workout 2: beats workout 1
      final workout2Id = await testDb.workouts.insertOne(
        createTestWorkout(
          name: 'Workout 2',
        ),
      );
      await testDb.gymSets.insertOne(
        createTestSet(
          workoutId: workout2Id,
          name: 'Bench Press',
          weight: 110,
        ),
      );

      final hasRecords = await workoutHasRecords(workout2Id);
      expect(hasRecords, isTrue);

      final recordCount = await getWorkoutRecordCount(workout2Id);
      expect(recordCount, greaterThan(0));
    });
  });
}
