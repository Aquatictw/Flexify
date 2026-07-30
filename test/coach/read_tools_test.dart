import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/coach/read_tools.dart';
import 'package:jackedlog/database/database.dart';

import '../test_helpers.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = await createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  Future<GymSet> addSet({
    required String name,
    required double weight,
    double reps = 5,
    String unit = 'kg',
    DateTime? created,
    bool hidden = false,
    bool warmup = false,
    bool cardio = false,
    int sequence = 0,
    int? setOrder,
  }) {
    return database.into(database.gymSets).insertReturning(
          GymSetsCompanion.insert(
            name: name,
            reps: reps,
            weight: weight,
            unit: unit,
            created: created ?? DateTime.now(),
            hidden: Value(hidden),
            warmup: Value(warmup),
            cardio: Value(cardio),
            sequence: Value(sequence),
            setOrder: Value(setOrder),
          ),
        );
  }

  Future<Map<String, Object?>> history(
    String exercise, {
    Object? limit,
    List<String>? vocabulary,
  }) {
    return getExerciseHistoryResult(
      arguments: <String, Object?>{
        'exercise': exercise,
        if (limit != null) 'limit': limit,
      },
      exerciseVocabulary: vocabulary ?? <String>[exercise],
      settingsUnit: 'kg',
    );
  }

  FiveThreeOneBlock block({
    required int id,
    required DateTime created,
    required DateTime completed,
    double startSquat = 140,
    double squat = 150,
  }) {
    return FiveThreeOneBlock(
      id: id,
      created: created,
      squatTm: squat,
      benchTm: 105,
      deadliftTm: 190,
      pressTm: 62.5,
      startSquatTm: startSquat,
      startBenchTm: 100,
      startDeadliftTm: 180,
      startPressTm: 60,
      unit: 'kg',
      currentCycle: 4,
      currentWeek: 1,
      isActive: false,
      completed: completed,
      leaderSupplemental: 'bbb',
      anchorSupplemental: 'fsl',
      tmBumps: 3,
    );
  }

  group('exercise history', () {
    test('reports only performed working strength rows', () async {
      const name = 'Issue 08 Strict Press';
      final day = DateTime(2026, 7, 20, 12);
      await addSet(name: name, weight: 80, created: day);
      await addSet(name: name, weight: 81, created: day, hidden: true);
      await addSet(name: name, weight: 82, created: day, warmup: true);
      await addSet(name: name, weight: 83, created: day, cardio: true);
      await addSet(name: name, weight: 84, created: day, sequence: -1);
      await addSet(name: name, weight: 85, reps: -1, created: day);

      final result = await history(name);
      final text = result['text']! as String;

      expect(result['ok'], isTrue);
      expect(text, contains('2026-07-20: 80x5'));
      for (final excluded in <String>['81x5', '82x5', '83x5', '84x5']) {
        expect(text, isNot(contains(excluded)));
      }
      expect(text, isNot(contains('85x-1')));
    });

    test('groups days newest-first and describes truncation only when needed',
        () async {
      const name = 'Issue 08 Day Lift';
      await addSet(
        name: name,
        weight: 70,
        created: DateTime(2026, 7, 18, 12),
      );
      await addSet(
        name: name,
        weight: 80,
        created: DateTime(2026, 7, 19, 12),
      );
      await addSet(
        name: name,
        weight: 90,
        created: DateTime(2026, 7, 20, 12),
      );

      final limited = await history(name, limit: 2);
      final limitedText = limited['text']! as String;
      expect(limitedText, contains('2 most recent of 3 sessions'));
      expect(
        limitedText.indexOf('2026-07-20'),
        lessThan(limitedText.indexOf('2026-07-19')),
      );
      expect(limitedText, isNot(contains('2026-07-18')));

      final complete = await history(name, limit: 3);
      final completeText = complete['text']! as String;
      expect(completeText, contains('— 3 sessions (kg)'));
      expect(completeText, isNot(contains('most recent of')));
    });

    test('defaults to 10 sessions and clamps limits above 25', () async {
      const name = 'Issue 08 Limit Lift';
      for (var day = 1; day <= 26; day++) {
        await addSet(
          name: name,
          weight: 50 + day.toDouble(),
          created: DateTime(2026, 6, day, 12),
        );
      }

      final defaultResult = await history(name);
      expect(
        defaultResult['text'],
        contains('10 most recent of 26 sessions'),
      );

      final clamped = await history(name, limit: 100);
      expect(clamped['text'], contains('25 most recent of 26 sessions'));
    });

    test('collapses consecutive identical sets', () async {
      const name = 'Issue 08 BBB Lift';
      for (var order = 0; order < 5; order++) {
        await addSet(
          name: name,
          weight: 60,
          reps: 10,
          created: DateTime(2026, 7, 20, 12),
          setOrder: order,
        );
      }

      final result = await history(name);
      expect(result['text'], contains('60x10 (x5)'));
    });

    test('unknown names return a suggestion instead of empty success',
        () async {
      final result = await history(
        'Bench Pres',
        vocabulary: const <String>['Bench Press', 'Back Squat'],
      );

      expect(result['ok'], isFalse);
      expect(result['error'], contains('did you mean'));
      expect(result['error'], contains('Bench Press'));
      expect(result, isNot(containsPair('text', anything)));
    });

    test('known names with no performed rows are valid empty results',
        () async {
      const name = 'Bench Press';
      final result = await history(name);

      expect(result['ok'], isTrue);
      expect(result['text'], 'No performed sets recorded for $name.');
    });
  });

  test('records use app record helpers and ignore hidden rows', () async {
    const name = 'Issue 08 Record Lift';
    await addSet(
      name: name,
      weight: 100,
      created: DateTime(2026, 5, 1, 12),
    );
    await addSet(
      name: name,
      weight: 110,
      reps: 3,
      created: DateTime(2026, 5, 2, 12),
    );
    await addSet(
      name: name,
      weight: 200,
      reps: 1,
      hidden: true,
      created: DateTime(2026, 5, 3, 12),
    );

    final result = await getRecordsResult(
      arguments: const <String, Object?>{'exercise': name},
      exerciseVocabulary: const <String>[name],
      settingsUnit: 'kg',
    );
    final text = result['text']! as String;

    expect(result['ok'], isTrue);
    expect(text, contains('Best weight: 110 x 3 (2026-05-02)'));
    expect(text, contains('Rep PRs: 3:110, 5:100'));
    expect(text, isNot(contains('200')));
  });

  group('block history', () {
    test('renders start-to-end TMs with limit and total', () async {
      final blocks = <FiveThreeOneBlock>[
        block(
          id: 2,
          created: DateTime(2026, 4),
          completed: DateTime(2026, 6, 10),
        ),
        block(
          id: 1,
          created: DateTime(2026),
          completed: DateTime(2026, 3, 10),
          startSquat: 130,
          squat: 140,
        ),
      ];

      final result = await getBlockHistoryResult(
        arguments: const <String, Object?>{'limit': 1},
        completedBlocks: () async => blocks,
      );
      final text = result['text']! as String;

      expect(
        text,
        contains('Block history — 1 most recent of 2 completed blocks'),
      );
      expect(text, contains('2026-04-01 to 2026-06-10 (kg)'));
      expect(text, contains('squat 140->150'));
      expect(text, contains('bench 100->105'));
      expect(text, contains('leader BBB 5x10, anchor FSL 5x5'));
      expect(text, isNot(contains('2026-01-01')));
    });

    test('returns a valid empty answer', () async {
      final result = await getBlockHistoryResult(
        arguments: const <String, Object?>{},
        completedBlocks: () async => <FiveThreeOneBlock>[],
      );

      expect(result, <String, Object?>{
        'ok': true,
        'text': 'No completed blocks yet.',
      });
    });
  });

  test('runReadTool dispatches every read name and rejects unknown tools',
      () async {
    const vocabulary = <String>['Bench Press'];
    final historyResult = await runReadTool(
      name: getExerciseHistoryTool,
      arguments: const <String, Object?>{'exercise': 'Bench Press'},
      exerciseVocabulary: vocabulary,
      settingsUnit: 'kg',
    );
    final recordsResult = await runReadTool(
      name: getRecordsTool,
      arguments: const <String, Object?>{'exercise': 'Bench Press'},
      exerciseVocabulary: vocabulary,
      settingsUnit: 'kg',
    );
    final blocksResult = await runReadTool(
      name: getBlockHistoryTool,
      arguments: const <String, Object?>{},
      exerciseVocabulary: vocabulary,
      settingsUnit: 'kg',
      completedBlocks: () async => <FiveThreeOneBlock>[],
    );
    final unknownResult = await runReadTool(
      name: 'read_everything',
      arguments: const <String, Object?>{},
      exerciseVocabulary: vocabulary,
      settingsUnit: 'kg',
    );

    expect(historyResult['ok'], isTrue);
    expect(recordsResult['ok'], isTrue);
    expect(blocksResult['ok'], isTrue);
    expect(unknownResult['ok'], isFalse);
    for (final name in readToolNames) {
      expect(unknownResult['error'], contains(name));
    }
  });

  test('unknown argument keys return retryable errors', () async {
    final result = await getRecordsResult(
      arguments: const <String, Object?>{
        'exercise': 'Bench Press',
        'everything': true,
      },
      exerciseVocabulary: const <String>['Bench Press'],
      settingsUnit: 'kg',
    );

    expect(result['ok'], isFalse);
    expect(result['error'], contains("does not take 'everything'"));
    expect(result['error'], contains('Allowed keys are exercise'));
  });
}
