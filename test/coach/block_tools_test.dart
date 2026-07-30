import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/coach/block_tools.dart';
import 'package:jackedlog/coach/widgets/proposal_card.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/fivethreeone/fivethreeone_state.dart';
import 'package:jackedlog/fivethreeone/schemes.dart';

import '../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late FiveThreeOneState state;

  setUp(() async {
    database = await createTestDatabase();
    await _replaceBlock(database);
    state = FiveThreeOneState();
    await state.refresh();
  });

  tearDown(() async {
    state.dispose();
    await database.close();
  });

  Future<Map<String, Object?>> propose(
    List<Map<String, Object?>> ops, {
    FiveThreeOneBlock? block,
    List<String> vocabulary = const <String>[],
    String rationale =
        'The 5/3/1 progression distinguishes cycle bumps from corrections.',
  }) =>
      proposeBlockChanges(
        arguments: <String, Object?>{
          'ops': ops,
          'rationale': rationale,
        },
        block: block ?? state.activeBlock,
        exerciseVocabulary: vocabulary,
        settingsUnit: 'kg',
      );

  Future<BlockProposal> proposal(
    List<Map<String, Object?>> ops, {
    FiveThreeOneBlock? block,
  }) async {
    final result = await propose(ops, block: block);
    expect(result['ok'], isTrue, reason: '${result['error']}');
    return BlockProposal.fromJson(
      Map<String, Object?>.from(result['proposal']! as Map),
    );
  }

  group('proposal planning', () {
    final operations = <String, Map<String, Object?>>{
      'bump_tms': <String, Object?>{'op': 'bump_tms'},
      'unbump_tms': <String, Object?>{'op': 'unbump_tms'},
      'correct_tm': <String, Object?>{
        'op': 'correct_tm',
        'lift': 'bench',
        'value': 97.5,
      },
      'advance_week': <String, Object?>{'op': 'advance_week'},
      'go_back_week': <String, Object?>{'op': 'go_back_week'},
      'set_supplemental': <String, Object?>{
        'op': 'set_supplemental',
        'cycle': 'leader',
        'supplemental': 'fsl',
      },
      'create_exercise': <String, Object?>{
        'op': 'create_exercise',
        'exercise': '  Zercher Carry  ',
      },
    };

    for (final entry in operations.entries) {
      test('${entry.key} produces a reviewable proposal', () async {
        final result = await propose(<Map<String, Object?>>[entry.value]);

        expect(result['ok'], isTrue, reason: '${result['error']}');
        expect(result['status'], 'pending_confirmation');
        final planned = BlockProposal.fromJson(
          Map<String, Object?>.from(result['proposal']! as Map),
        );
        expect(planned.ops.single.kind.wire, entry.key);
        expect(planned.changes, isNotEmpty);
        expect(planned.bumpSemantics, isNotEmpty);
        if (entry.key == 'create_exercise') {
          expect(planned.ops.single.exercise, 'Zercher Carry');
        }
      });
    }

    test('bump proposal uses state rounding and explicit counter semantics',
        () async {
      final planned = await proposal(<Map<String, Object?>>[
        <String, Object?>{'op': 'bump_tms'},
      ]);

      expect(planned.changes.map((change) => change.after), <String>[
        '144.5 kg',
        '102.2 kg',
        '184.5 kg',
        '62.2 kg',
      ]);
      expect(planned.bumpSemantics, contains('Counts as a cycle bump'));
      expect(planned.countsAsCycleBump, isTrue);
      expect(planned.tmBumpsBefore, 1);
      expect(planned.tmBumpsAfter, 2);
    });

    test('correct_tm proposal says the bump counter stays put', () async {
      final planned = await proposal(<Map<String, Object?>>[
        <String, Object?>{
          'op': 'correct_tm',
          'lift': 'bench',
          'value': 97.5,
        },
      ]);

      expect(
        planned.bumpSemantics,
        contains('Does not count as a cycle bump'),
      );
      expect(planned.countsAsCycleBump, isFalse);
      expect(planned.tmBumpsBefore, 1);
      expect(planned.tmBumpsAfter, 1);
      expect(planned.changes.single.toJson(), <String, Object?>{
        'label': 'Bench TM',
        'before': '100 kg',
        'after': '97.5 kg',
        'detail': 'does not count as a cycle bump',
      });
    });

    test('proposing a mixed request writes no block or exercise data',
        () async {
      final beforeBlock =
          await database.select(database.fiveThreeOneBlocks).getSingle();
      final beforeSetCount = await database
          .select(database.gymSets)
          .get()
          .then((rows) => rows.length);

      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{'op': 'bump_tms'},
        <String, Object?>{
          'op': 'correct_tm',
          'lift': 'bench',
          'value': 97.5,
        },
        <String, Object?>{
          'op': 'set_supplemental',
          'cycle': 'leader',
          'supplemental': 'fsl',
        },
        <String, Object?>{
          'op': 'create_exercise',
          'exercise': 'Pin Squat Hold',
        },
      ]);

      expect(result['ok'], isFalse);
      expect(
        await database.select(database.fiveThreeOneBlocks).getSingle(),
        beforeBlock,
      );
      expect(
        await database
            .select(database.gymSets)
            .get()
            .then((rows) => rows.length),
        beforeSetCount,
      );
    });

    test('proposal survives JSON storage losslessly', () async {
      final original = await proposal(<Map<String, Object?>>[
        <String, Object?>{
          'op': 'correct_tm',
          'lift': 'bench',
          'value': 97.5,
        },
        <String, Object?>{
          'op': 'set_supplemental',
          'cycle': 'leader',
          'supplemental': 'fsl',
        },
        <String, Object?>{
          'op': 'create_exercise',
          'exercise': 'Pin Squat Hold',
        },
      ]);
      final decoded = jsonDecode(jsonEncode(original.toJson()));
      final restored = BlockProposal.fromJson(
        Map<String, Object?>.from(decoded as Map),
      );

      expect(restored.toJson(), original.toJson());
      expect(
        restored.ops.map((op) => op.kind),
        original.ops.map((op) => op.kind),
      );
      expect(restored.rationale, original.rationale);
      expect(
        restored.changes.map((change) => change.toJson()),
        original.changes.map((change) => change.toJson()),
      );
      expect(restored.bumpSemantics, original.bumpSemantics);
      expect(restored.tmBumpsBefore, original.tmBumpsBefore);
      expect(restored.tmBumpsAfter, original.tmBumpsAfter);
    });
  });

  group('confirmed writes', () {
    test('correct_tm changes one TM and leaves tm_bumps exactly unchanged',
        () async {
      final planned = await proposal(<Map<String, Object?>>[
        <String, Object?>{
          'op': 'correct_tm',
          'lift': 'bench',
          'value': 97.5,
        },
      ]);

      final result = await applyBlockProposal(
        proposal: planned,
        fiveThreeOneState: state,
        settingsUnit: 'kg',
      );
      final row =
          await database.select(database.fiveThreeOneBlocks).getSingle();

      expect(result['ok'], isTrue, reason: '${result['error']}');
      expect(row.benchTm, 97.5);
      expect(row.tmBumps, 1);
      expect(row.squatTm, 140);
      expect(row.deadliftTm, 180);
      expect(row.pressTm, 60);
      expect(planned.countsAsCycleBump, isFalse);
    });

    test('bump_tms moves every TM and increments tm_bumps exactly once',
        () async {
      final before =
          await database.select(database.fiveThreeOneBlocks).getSingle();
      final planned = await proposal(<Map<String, Object?>>[
        <String, Object?>{'op': 'bump_tms'},
      ]);

      final result = await applyBlockProposal(
        proposal: planned,
        fiveThreeOneState: state,
        settingsUnit: 'kg',
      );
      final row =
          await database.select(database.fiveThreeOneBlocks).getSingle();

      expect(result['ok'], isTrue, reason: '${result['error']}');
      expect(row.tmBumps, before.tmBumps + 1);
      expect(row.squatTm, before.squatTm + 4.5);
      expect(row.deadliftTm, before.deadliftTm + 4.5);
      expect(row.benchTm, before.benchTm + 2.2);
      expect(row.pressTm, before.pressTm + 2.2);
      expect(planned.countsAsCycleBump, isTrue);
    });

    test('coach bump preserves the Back-button unbump invariant', () async {
      await _replaceBlock(
        database,
        currentCycle: cycleLeader1,
        currentWeek: 3,
        tmBumps: 0,
      );
      await state.refresh();
      expect(bumpsThroughCycle(cycleLeader1), 0);
      expect(state.needsTmUnbump, isFalse);

      final bump = await proposal(<Map<String, Object?>>[
        <String, Object?>{'op': 'bump_tms'},
      ]);
      expect(
        (await applyBlockProposal(
          proposal: bump,
          fiveThreeOneState: state,
          settingsUnit: 'kg',
        ))['ok'],
        isTrue,
      );
      final advance = await proposal(<Map<String, Object?>>[
        <String, Object?>{'op': 'advance_week'},
      ]);
      expect(
        (await applyBlockProposal(
          proposal: advance,
          fiveThreeOneState: state,
          settingsUnit: 'kg',
        ))['ok'],
        isTrue,
      );

      expect(state.activeBlock!.currentCycle, cycleLeader2);
      expect(state.activeBlock!.currentWeek, 1);
      expect(state.activeBlock!.tmBumps, 1);
      expect(state.needsTmUnbump, isTrue);
    });

    test('a correction at the same position does not create an unbump',
        () async {
      await _replaceBlock(
        database,
        currentCycle: cycleLeader1,
        currentWeek: 3,
        tmBumps: 0,
      );
      await state.refresh();
      expect(bumpsThroughCycle(cycleLeader1), 0);

      final correction = await proposal(<Map<String, Object?>>[
        <String, Object?>{
          'op': 'correct_tm',
          'lift': 'bench',
          'value': 97.5,
        },
      ]);
      await applyBlockProposal(
        proposal: correction,
        fiveThreeOneState: state,
        settingsUnit: 'kg',
      );
      final advance = await proposal(<Map<String, Object?>>[
        <String, Object?>{'op': 'advance_week'},
      ]);
      await applyBlockProposal(
        proposal: advance,
        fiveThreeOneState: state,
        settingsUnit: 'kg',
      );

      expect(state.activeBlock!.currentCycle, cycleLeader2);
      expect(state.activeBlock!.currentWeek, 1);
      expect(state.activeBlock!.tmBumps, 0);
      expect(state.needsTmUnbump, isFalse);
    });

    test('Apply revalidates against a block that moved after rendering',
        () async {
      final planned = await proposal(<Map<String, Object?>>[
        <String, Object?>{'op': 'unbump_tms'},
      ]);
      await state.unbumpTms();
      final before =
          await database.select(database.fiveThreeOneBlocks).getSingle();

      final result = await applyBlockProposal(
        proposal: planned,
        fiveThreeOneState: state,
        settingsUnit: 'kg',
      );

      expect(result['ok'], isFalse);
      expect(result['status'], 'failed');
      expect(result['error'], contains('tm_bumps is 0'));
      expect(
        await database.select(database.fiveThreeOneBlocks).getSingle(),
        before,
      );
    });

    test('set_supplemental and create_exercise use their sanctioned rows',
        () async {
      final planned = await proposal(<Map<String, Object?>>[
        <String, Object?>{
          'op': 'set_supplemental',
          'cycle': 'leader',
          'supplemental': 'fsl',
        },
        <String, Object?>{
          'op': 'create_exercise',
          'exercise': 'Pin Squat Hold',
        },
      ]);

      final result = await applyBlockProposal(
        proposal: planned,
        fiveThreeOneState: state,
        settingsUnit: 'kg',
      );
      final block =
          await database.select(database.fiveThreeOneBlocks).getSingle();
      final registration = await (database.select(database.gymSets)
            ..where((row) => row.name.equals('Pin Squat Hold')))
          .getSingle();

      expect(result['ok'], isTrue, reason: '${result['error']}');
      expect(block.leaderSupplemental, supplementalFsl);
      expect(block.tmBumps, 1);
      expect(registration.hidden, isTrue);
      expect(registration.workoutId, null);
      expect(registration.reps, 1);
      expect(registration.sequence, 0);
    });
  });

  group('refusals', () {
    test('anchor BBB is refused in favour of FSL', () async {
      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{
          'op': 'set_supplemental',
          'cycle': 'anchor',
          'supplemental': 'bbb',
        },
      ]);
      expect(result['ok'], isFalse);
      expect(result['error'], contains('FSL'));
    });

    test('unsupported supplemental names explain the supported choices',
        () async {
      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{
          'op': 'set_supplemental',
          'cycle': 'leader',
          'supplemental': 'ssl',
        },
      ]);
      expect(result['ok'], isFalse);
      expect(result['error'], contains('BBB and FSL'));
    });

    test('unbump at zero is refused', () async {
      await _replaceBlock(database, tmBumps: 0);
      await state.refresh();
      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{'op': 'unbump_tms'},
      ]);
      expect(result['ok'], isFalse);
      expect(result['error'], contains('tm_bumps is 0'));
    });

    test('going back from the first week is refused', () async {
      await _replaceBlock(
        database,
        currentCycle: cycleLeader1,
        currentWeek: 1,
      );
      await state.refresh();
      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{'op': 'go_back_week'},
      ]);
      expect(result['ok'], isFalse);
      expect(result['error'], contains('first week'));
    });

    test('advancing beyond the TM test is refused', () async {
      await _replaceBlock(
        database,
        currentCycle: cycleTmTest,
        currentWeek: 1,
      );
      await state.refresh();
      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{'op': 'advance_week'},
      ]);
      expect(result['ok'], isFalse);
      expect(result['error'], contains('Start a new block'));
    });

    test('correct_tm requires a value', () async {
      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{'op': 'correct_tm', 'lift': 'bench'},
      ]);
      expect(result['ok'], isFalse);
      expect(result['error'], contains('value'));
    });

    test('unknown op keys are refused', () async {
      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{'op': 'bump_tms', 'mystery': true},
      ]);
      expect(result['ok'], isFalse);
      expect(result['error'], contains("'mystery'"));
    });

    test('bump and unbump cannot be proposed together', () async {
      final result = await propose(<Map<String, Object?>>[
        <String, Object?>{'op': 'bump_tms'},
        <String, Object?>{'op': 'unbump_tms'},
      ]);
      expect(result['ok'], isFalse);
      expect(result['error'], contains('conflict'));
    });
  });

  test('declining reports the decision and writes nothing', () async {
    final planned = await proposal(<Map<String, Object?>>[
      <String, Object?>{'op': 'bump_tms'},
    ]);
    final beforeBlock =
        await database.select(database.fiveThreeOneBlocks).getSingle();
    final beforeSetCount = await database
        .select(database.gymSets)
        .get()
        .then((rows) => rows.length);

    final result = declinedBlockProposalResult(planned);

    expect(result['ok'], isTrue);
    expect(result['status'], 'declined');
    expect(result['note'], contains('user declined'));
    expect(result['note'], contains('Nothing was written'));
    expect(
      await database.select(database.fiveThreeOneBlocks).getSingle(),
      beforeBlock,
    );
    expect(
      await database.select(database.gymSets).get().then((rows) => rows.length),
      beforeSetCount,
    );
  });

  testWidgets('confirmation card shows semantics and pending actions',
      (tester) async {
    const planned = BlockProposal(
      ops: <BlockOp>[BlockOp(kind: BlockOpKind.bumpTms)],
      rationale: 'The cycle is complete, so the book calls for a TM bump.',
      changes: <BlockChange>[
        BlockChange(
          label: 'Bench TM',
          before: '100 kg',
          after: '102.2 kg',
          detail: 'counts as a cycle bump',
        ),
      ],
      bumpSemantics:
          "Counts as a cycle bump: the block's bump counter goes from 1 to 2.",
      tmBumpsBefore: 1,
      tmBumpsAfter: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalCard(
            proposal: planned,
            status: ProposalCardStatus.pending,
            onApply: () async {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text(planned.bumpSemantics), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);
  });
}

Future<void> _replaceBlock(
  AppDatabase database, {
  int currentCycle = cycleLeader2,
  int currentWeek = 2,
  int tmBumps = 1,
}) async {
  await database.delete(database.fiveThreeOneBlocks).go();
  await database.into(database.fiveThreeOneBlocks).insert(
        FiveThreeOneBlocksCompanion.insert(
          created: DateTime(2026, 7, 29),
          squatTm: 140,
          benchTm: 100,
          deadliftTm: 180,
          pressTm: 60,
          unit: 'kg',
          currentCycle: Value(currentCycle),
          currentWeek: Value(currentWeek),
          leaderSupplemental: const Value(supplementalBbb),
          anchorSupplemental: const Value(supplementalFsl),
          tmBumps: Value(tmBumps),
        ),
      );
}
