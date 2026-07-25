import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/workouts/workout_state.dart';

import '../test_helpers.dart';

void main() {
  group('WorkoutState database integration', () {
    late AppDatabase db;
    late WorkoutState workoutState;
    late Plan testPlan;

    setUp(() async {
      db = await createTestDatabase();
      workoutState = WorkoutState();

      // Create a test plan
      testPlan = await db.into(db.plans).insertReturning(
            PlansCompanion.insert(
              days: 'Push',
              sequence: const Value(0),
              title: const Value('Push Day'),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('full workout lifecycle persists to database correctly', () async {
      // Verify no active workouts initially
      final initialActive =
          await (db.workouts.select()..where((w) => w.endTime.isNull())).get();
      expect(initialActive, isEmpty);

      // Start workout
      final workout = await workoutState.startWorkout(testPlan);
      expect(workout, isNotNull);

      // Verify workout created in DB with null endTime
      final activeWorkout = await (db.workouts.select()
            ..where((w) => w.id.equals(workout!.id)))
          .getSingle();
      expect(activeWorkout.name, equals('Push Day'));
      expect(activeWorkout.planId, equals(testPlan.id));
      expect(activeWorkout.endTime, isNull);
      expect(activeWorkout.startTime, isNotNull);

      // Add sets linked to workout
      final set1 = await db.gymSets.insertReturning(
        createTestSet(
          workoutId: workout?.id,
          name: 'Bench Press',
          setOrder: 0,
        ),
      );

      final set2 = await db.gymSets.insertReturning(
        createTestSet(
          workoutId: workout?.id,
          name: 'Bench Press',
          weight: 105,
          reps: 8,
          setOrder: 1,
        ),
      );

      final set3 = await db.gymSets.insertReturning(
        createTestSet(
          workoutId: workout?.id,
          name: 'Squat',
          weight: 140,
          reps: 5,
          sequence: 1,
          setOrder: 0,
        ),
      );

      // Verify sets are linked to workout
      final workoutSets = await (db.gymSets.select()
            ..where((s) => s.workoutId.equals(workout!.id))
            ..orderBy([
              (s) => OrderingTerm(expression: s.sequence),
              (s) => OrderingTerm(expression: s.setOrder),
            ]))
          .get();

      expect(workoutSets.length, equals(3));
      expect(workoutSets[0].id, equals(set1.id));
      expect(workoutSets[0].name, equals('Bench Press'));
      expect(workoutSets[0].sequence, equals(0));
      expect(workoutSets[1].id, equals(set2.id));
      expect(workoutSets[2].id, equals(set3.id));
      expect(workoutSets[2].sequence, equals(1));

      // Stop workout
      await workoutState.stopWorkout();

      // Verify endTime is populated in database
      final stoppedWorkout = await (db.workouts.select()
            ..where((w) => w.id.equals(workout!.id)))
          .getSingle();
      expect(stoppedWorkout.endTime, isNotNull);
      // Same-millisecond start/stop is legitimate here, so only assert the
      // end time never precedes the start.
      expect(
        stoppedWorkout.endTime!.isBefore(stoppedWorkout.startTime),
        isFalse,
      );

      // Verify sets persist after workout stops
      final persistedSets = await (db.gymSets.select()
            ..where((s) => s.workoutId.equals(workout!.id)))
          .get();
      expect(persistedSets.length, equals(3));

      // Verify no active workouts remain
      final finalActive =
          await (db.workouts.select()..where((w) => w.endTime.isNull())).get();
      expect(finalActive, isEmpty);
    });

    test('single active workout enforcement in database', () async {
      // Start first workout
      final workout1 = await workoutState.startWorkout(testPlan);
      expect(workout1, isNotNull);

      // Add sets to first workout
      await db.gymSets.insertOne(
        createTestSet(
          workoutId: workout1!.id,
          name: 'Exercise 1',
        ),
      );

      // Verify one active workout in DB
      var activeWorkouts =
          await (db.workouts.select()..where((w) => w.endTime.isNull())).get();
      expect(activeWorkouts.length, equals(1));
      expect(activeWorkouts[0].id, equals(workout1.id));

      // Create second plan
      final plan2 = await db.into(db.plans).insertReturning(
            PlansCompanion.insert(
              days: 'Pull',
              sequence: const Value(1),
              title: const Value('Pull Day'),
            ),
          );

      // Attempt to start second workout
      final workout2 = await workoutState.startWorkout(plan2);
      expect(workout2, isNull);

      // Verify still only one active workout in DB
      activeWorkouts =
          await (db.workouts.select()..where((w) => w.endTime.isNull())).get();
      expect(activeWorkouts.length, equals(1));
      expect(activeWorkouts[0].id, equals(workout1.id));

      // Verify no workouts created for second plan
      final plan2Workouts = await (db.workouts.select()
            ..where((w) => w.planId.equals(plan2.id)))
          .get();
      expect(plan2Workouts, isEmpty);

      // Verify WorkoutState still points to first workout
      expect(workoutState.activeWorkout!.id, equals(workout1.id));
      expect(workoutState.activePlan!.id, equals(testPlan.id));
    });

    test('resume workout restores state from database', () async {
      // Create completed workout directly in database
      final originalStart = DateTime.now().subtract(const Duration(hours: 2));
      final originalEnd = DateTime.now().subtract(const Duration(hours: 1));

      final completedWorkout = await db.into(db.workouts).insertReturning(
            WorkoutsCompanion.insert(
              startTime: originalStart,
              endTime: Value(originalEnd),
              planId: Value(testPlan.id),
              name: const Value('Completed Workout'),
              notes: const Value('Test notes'),
            ),
          );

      // Add sets to completed workout
      final set1Id = await db.gymSets.insertOne(
        createTestSet(
          workoutId: completedWorkout.id,
          name: 'Deadlift',
          weight: 200,
          reps: 5,
          setOrder: 0,
        ),
      );

      final set2Id = await db.gymSets.insertOne(
        createTestSet(
          workoutId: completedWorkout.id,
          name: 'Deadlift',
          weight: 210,
          reps: 3,
          setOrder: 1,
        ),
      );

      // Verify workout is completed in DB
      var dbWorkout = await (db.workouts.select()
            ..where((w) => w.id.equals(completedWorkout.id)))
          .getSingle();
      expect(dbWorkout.endTime, isNotNull);

      // Resume workout
      final plan = await workoutState.resumeWorkout(completedWorkout);
      expect(plan, isNotNull);
      expect(plan!.id, equals(testPlan.id));

      // Verify workout is now active in DB (endTime = null)
      dbWorkout = await (db.workouts.select()
            ..where((w) => w.id.equals(completedWorkout.id)))
          .getSingle();
      expect(dbWorkout.endTime, isNull);

      // Verify startTime was adjusted to preserve duration
      final originalDuration = originalEnd.difference(originalStart);
      final elapsedSinceResume = DateTime.now().difference(dbWorkout.startTime);
      // Should be close to original duration (within 1 second tolerance)
      expect(
        elapsedSinceResume.inSeconds,
        closeTo(originalDuration.inSeconds, 1),
      );

      // Verify sets are still linked and unchanged
      final sets = await (db.gymSets.select()
            ..where((s) => s.workoutId.equals(completedWorkout.id))
            ..orderBy([(s) => OrderingTerm(expression: s.setOrder)]))
          .get();
      expect(sets.length, equals(2));
      expect(sets[0].id, equals(set1Id));
      expect(sets[0].weight, equals(200.0));
      expect(sets[1].id, equals(set2Id));
      expect(sets[1].weight, equals(210.0));

      // Verify WorkoutState correctly restored
      expect(workoutState.activeWorkout, isNotNull);
      expect(workoutState.activeWorkout!.id, equals(completedWorkout.id));
      expect(workoutState.activeWorkout!.name, equals('Completed Workout'));
      expect(workoutState.activeWorkout!.notes, equals('Test notes'));
      expect(workoutState.activePlan!.id, equals(testPlan.id));
    });

    test('resume freeform workout without planId', () async {
      // Create freeform workout (no planId)
      final freeformWorkout = await db.into(db.workouts).insertReturning(
            WorkoutsCompanion.insert(
              startTime: DateTime.now().subtract(const Duration(hours: 1)),
              endTime: Value(DateTime.now()),
              planId: const Value(null),
              name: const Value('Morning Workout'),
            ),
          );

      // Add sets to freeform workout
      await db.gymSets.insertOne(
        createTestSet(
          workoutId: freeformWorkout.id,
          name: 'Push Ups',
        ),
      );

      // Resume freeform workout
      final plan = await workoutState.resumeWorkout(freeformWorkout);
      expect(plan, isNotNull);
      expect(plan!.id, equals(-1)); // Temporary plan

      // Verify workout is active in DB
      final dbWorkout = await (db.workouts.select()
            ..where((w) => w.id.equals(freeformWorkout.id)))
          .getSingle();
      expect(dbWorkout.endTime, isNull);
      expect(dbWorkout.planId, isNull); // Still null

      // Verify WorkoutState has temporary plan
      expect(workoutState.activePlan!.id, equals(-1));
      expect(workoutState.activePlan!.title, equals('Morning Workout'));
      expect(workoutState.activePlan!.days, equals('Morning Workout'));
    });

    test('discard workout deletes from database', () async {
      // Start workout
      final workout = await workoutState.startWorkout(testPlan);
      expect(workout, isNotNull);
      final workoutId = workout!.id;

      // Add multiple sets
      await db.gymSets.insertOne(
        createTestSet(workoutId: workoutId, name: 'Exercise 1'),
      );
      await db.gymSets.insertOne(
        createTestSet(workoutId: workoutId, name: 'Exercise 1'),
      );
      await db.gymSets.insertOne(
        createTestSet(workoutId: workoutId, name: 'Exercise 2', sequence: 1),
      );

      // Verify workout and sets exist
      var dbWorkout = await (db.workouts.select()
            ..where((w) => w.id.equals(workoutId)))
          .getSingleOrNull();
      expect(dbWorkout, isNotNull);

      var dbSets = await (db.gymSets.select()
            ..where((s) => s.workoutId.equals(workoutId)))
          .get();
      expect(dbSets.length, equals(3));

      // Discard workout
      await workoutState.discardWorkout();

      // Verify workout deleted from DB
      dbWorkout = await (db.workouts.select()
            ..where((w) => w.id.equals(workoutId)))
          .getSingleOrNull();
      expect(dbWorkout, isNull);

      // Verify all sets deleted from DB
      dbSets = await (db.gymSets.select()
            ..where((s) => s.workoutId.equals(workoutId)))
          .get();
      expect(dbSets, isEmpty);

      // Verify state cleared
      expect(workoutState.hasActiveWorkout, isFalse);
    });

    test('workout with mixed set types (regular, warmup, cardio)', () async {
      // Start workout
      final workout = await workoutState.startWorkout(testPlan);
      expect(workout, isNotNull);

      // Add regular strength sets
      await db.gymSets.insertOne(
        createTestSet(
          workoutId: workout!.id,
          name: 'Bench Press',
          setOrder: 0,
        ),
      );

      // Add warmup set
      await db.gymSets.insertOne(
        createTestSet(
          workoutId: workout.id,
          name: 'Bench Press',
          weight: 60,
          reps: 15,
          setOrder: 1,
          warmup: true,
        ),
      );

      // Add cardio set
      await db.gymSets.insertOne(
        createTestSet(
          workoutId: workout.id,
          name: 'Running',
          duration: 600,
          distance: 2.5,
          sequence: 1,
          setOrder: 0,
          cardio: true,
        ),
      );

      // Stop workout
      await workoutState.stopWorkout();

      // Verify all set types persist correctly
      final sets = await (db.gymSets.select()
            ..where((s) => s.workoutId.equals(workout.id))
            ..orderBy([
              (s) => OrderingTerm(expression: s.sequence),
              (s) => OrderingTerm(expression: s.setOrder),
            ]))
          .get();

      expect(sets.length, equals(3));

      // Regular set
      expect(sets[0].name, equals('Bench Press'));
      expect(sets[0].warmup, isFalse);
      expect(sets[0].cardio, isFalse);
      expect(sets[0].weight, equals(100.0));

      // Warmup set
      expect(sets[1].name, equals('Bench Press'));
      expect(sets[1].warmup, isTrue);
      expect(sets[1].cardio, isFalse);
      expect(sets[1].weight, equals(60.0));

      // Cardio set
      expect(sets[2].name, equals('Running'));
      expect(sets[2].warmup, isFalse);
      expect(sets[2].cardio, isTrue);
      expect(sets[2].duration, equals(600.0));
      expect(sets[2].distance, equals(2.5));
    });

    test('refresh loads active workout from database on initialization',
        () async {
      // Create active workout directly in DB (simulating app restart)
      final activeWorkout = await db.into(db.workouts).insertReturning(
            WorkoutsCompanion.insert(
              startTime: DateTime.now().subtract(const Duration(minutes: 30)),
              endTime: const Value(null),
              planId: Value(testPlan.id),
              name: const Value('Active Before Restart'),
            ),
          );

      await db.gymSets.insertOne(
        createTestSet(
          workoutId: activeWorkout.id,
          name: 'Ongoing Exercise',
        ),
      );

      // Create new WorkoutState (simulating app restart)
      final newWorkoutState = WorkoutState();

      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify workout was loaded
      expect(newWorkoutState.hasActiveWorkout, isTrue);
      expect(newWorkoutState.activeWorkout, isNotNull);
      expect(newWorkoutState.activeWorkout!.id, equals(activeWorkout.id));
      expect(
        newWorkoutState.activeWorkout!.name,
        equals('Active Before Restart'),
      );
      expect(newWorkoutState.activePlan, isNotNull);
      expect(newWorkoutState.activePlan!.id, equals(testPlan.id));

      await db.close();
    });
  });
}
