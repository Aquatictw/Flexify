import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/constants.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/main.dart' as app;
import 'package:jackedlog/settings/settings_state.dart';
import 'package:jackedlog/workouts/workout_detail_page.dart';
import 'package:jackedlog/workouts/workout_state.dart';
import 'package:provider/provider.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase testDb;
  late Setting settings;

  setUp(() async {
    testDb = await createTestDatabase();
    app.db = testDb;
    settings =
        await testDb.into(testDb.settings).insertReturning(defaultSettings);
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('edit duration dialog exposes dates for cross-day workouts',
      (tester) async {
    final workout = await testDb.into(testDb.workouts).insertReturning(
          WorkoutsCompanion.insert(
            startTime: DateTime(2026, 1, 13, 23, 30),
            endTime: Value(DateTime(2026, 1, 15, 0, 30)),
            name: const Value('Late Workout'),
          ),
        );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsState(settings)),
          ChangeNotifierProvider(create: (_) => WorkoutState()),
        ],
        child: MaterialApp(
          home: WorkoutDetailPage(workout: workout),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Edit Workout'));
    await tester.pump();

    await tester.ensureVisible(find.text('25h 0m'));
    await tester.tap(find.text('25h 0m'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Start Date'), findsOneWidget);
    expect(find.text('2026 Jan 13'), findsOneWidget);
    expect(find.text('End Date'), findsOneWidget);
    expect(find.text('2026 Jan 15'), findsOneWidget);

    // Tear the tree down inside the test so drift's stream-cleanup timers run
    // before the binding checks for pending timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
