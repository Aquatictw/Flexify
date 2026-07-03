// Generates the README screenshots on a connected Android device.
//
// Run via ./scripts/readme-screenshots — it passes a dart-define so this
// test uses a throwaway database instead of the user's real data.

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/database/database_connection_native.dart';
import 'package:jackedlog/main.dart' as app;
import 'package:jackedlog/main.dart' show db;

Future<void> seed() async {
  // Idempotent: wipe demo data, keep hidden default exercises + default plans.
  await (db.delete(db.gymSets)..where((t) => t.hidden.equals(false))).go();
  await db.delete(db.workouts).go();
  await db.delete(db.notes).go();
  await db.delete(db.bodyweightEntries).go();

  final now = DateTime.now();

  // A few workouts across the past two weeks, so history + heatmap +
  // overview all have something to show.
  final workouts = [
    (
      name: 'Push Day',
      daysAgo: 1,
      sets: [
        ('Barbell bench press', 'Chest', [100.0, 100.0, 105.0], 5.0),
        ('Incline bench press', 'Chest', [70.0, 70.0, 70.0], 8.0),
        ('Dumbbell shoulder press', 'Shoulders', [26.0, 26.0, 26.0], 10.0),
        ('Triceps pushdown', 'Arms', [35.0, 35.0, 35.0], 12.0),
      ],
    ),
    (
      name: 'Pull Day',
      daysAgo: 3,
      sets: [
        ('Deadlift', 'Back', [160.0, 170.0, 180.0], 3.0),
        ('Pull-up', 'Back', [0.0, 0.0, 0.0], 10.0),
        ('Barbell bent-over row', 'Back', [80.0, 80.0, 85.0], 8.0),
        ('Barbell biceps curl', 'Arms', [30.0, 30.0, 30.0], 10.0),
      ],
    ),
    (
      name: 'Leg Day',
      daysAgo: 5,
      sets: [
        ('Squat', 'Legs', [120.0, 130.0, 140.0], 5.0),
        ('Leg press', 'Legs', [200.0, 220.0, 220.0], 10.0),
        ('Leg curl', 'Legs', [50.0, 50.0, 50.0], 12.0),
        ('Standing calf raise', 'Calves', [80.0, 80.0, 80.0], 15.0),
      ],
    ),
    (
      name: 'Push Day',
      daysAgo: 8,
      sets: [
        ('Barbell bench press', 'Chest', [95.0, 100.0, 100.0], 5.0),
        ('Incline bench press', 'Chest', [65.0, 70.0, 70.0], 8.0),
        ('Cable lateral raise', 'Shoulders', [12.0, 12.0, 12.0], 15.0),
        ('Triceps dip', 'Arms', [20.0, 20.0, 20.0], 10.0),
      ],
    ),
    (
      name: 'Pull Day',
      daysAgo: 10,
      sets: [
        ('Deadlift', 'Back', [150.0, 160.0, 170.0], 3.0),
        ('Lat pull-down', 'Back', [70.0, 70.0, 75.0], 10.0),
        ('Preacher curl', 'Arms', [25.0, 25.0, 25.0], 10.0),
      ],
    ),
    (
      name: 'Leg Day',
      daysAgo: 12,
      sets: [
        ('Squat', 'Legs', [110.0, 120.0, 130.0], 5.0),
        ('Romanian deadlift', 'Back', [100.0, 100.0, 100.0], 8.0),
        ('Leg extension', 'Legs', [55.0, 55.0, 55.0], 12.0),
      ],
    ),
  ];

  for (final w in workouts) {
    final start = DateTime(now.year, now.month, now.day - w.daysAgo, 17, 30);
    final workoutId = await db.workouts.insertOne(
      WorkoutsCompanion.insert(
        startTime: start,
        endTime: Value(start.add(const Duration(minutes: 72))),
        name: Value(w.name),
      ),
    );

    var minute = 0;
    var sequence = 0;
    for (final (name, category, weights, reps) in w.sets) {
      var setOrder = 0;
      for (final weight in weights) {
        await db.gymSets.insertOne(
          GymSetsCompanion.insert(
            name: name,
            category: Value(category),
            created: start.add(Duration(minutes: minute)),
            reps: reps,
            weight: weight,
            unit: 'kg',
            workoutId: Value(workoutId),
            sequence: Value(sequence),
            setOrder: Value(setOrder),
          ),
        );
        minute += 3;
        setOrder++;
      }
      sequence++;
    }
  }

  // A cardio entry so graphs have variety.
  await db.gymSets.insertOne(
    GymSetsCompanion.insert(
      name: 'Running',
      category: const Value('Cardio'),
      cardio: const Value(true),
      created: DateTime(now.year, now.month, now.day - 2, 8),
      reps: 0,
      weight: 0,
      unit: 'km',
      distance: const Value(5.2),
      duration: const Value(28),
    ),
  );

  // Bodyweight trend over the past month.
  for (var i = 0; i < 10; i++) {
    await db.bodyweightEntries.insertOne(
      BodyweightEntriesCompanion.insert(
        weight: 82.5 + i * 0.3,
        unit: 'kg',
        date: DateTime(now.year, now.month, now.day - i * 3, 7),
      ),
    );
  }

  await db.notes.insertOne(
    NotesCompanion.insert(
      title: 'Squat cues',
      content: 'Brace before descent. Knees out. Drive through mid-foot.',
      created: now.subtract(const Duration(days: 4)),
      updated: now.subtract(const Duration(days: 4)),
      color: const Value(0xFF7E57C2),
      sequence: const Value(0),
    ),
  );
  await db.notes.insertOne(
    NotesCompanion.insert(
      title: 'Cutting plan',
      content: '2400 kcal, 180g protein. Re-check weight Friday mornings.',
      created: now.subtract(const Duration(days: 9)),
      updated: now.subtract(const Duration(days: 2)),
      color: const Value(0xFF26A69A),
      sequence: const Value(1),
    ),
  );
}

/// Pump frames until [finder] matches, instead of pumpAndSettle (the splash
/// screen and nav bar have repeating animations that never settle).
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      throw StateError('Timed out waiting for $finder');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> settle(WidgetTester tester) async {
  // Let streams/queries emit and transitions finish.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture README screenshots', (tester) async {
    if (databaseFilename == 'jackedlog.sqlite') {
      fail(
        'Refusing to seed demo data into the real database. '
        'Run via ./scripts/readme-screenshots.',
      );
    }

    await seed();
    app.main();

    await waitFor(tester, find.byKey(const Key('PlansPage')));
    await settle(tester);
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();

    Future<void> shoot(String name) async {
      await settle(tester);
      await binding.takeScreenshot(name);
    }

    await shoot('readme_history');

    await tester.tap(find.byKey(const Key('PlansPage')));
    await shoot('readme_plans');

    await tester.tap(find.byKey(const Key('GraphsPage')));
    await settle(tester);
    await tester.tap(find.byTooltip('Overview'));
    await shoot('readme_overview');

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.byTooltip('Bodyweight Tracking'));
    await shoot('readme_bodyweight');

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.byKey(const Key('SettingsPage')));
    await shoot('readme_settings');
  });
}
