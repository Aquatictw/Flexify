import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/coach/block_tools.dart';
import 'package:jackedlog/coach/coach_state.dart';
import 'package:jackedlog/coach/coach_tools.dart';
import 'package:jackedlog/coach/coach_transport.dart';
import 'package:jackedlog/coach/read_tools.dart';
import 'package:jackedlog/coach/widgets/coach_message_list.dart';
import 'package:jackedlog/coach/widgets/proposal_card.dart';
import 'package:jackedlog/database/database.dart';
import 'package:jackedlog/fivethreeone/fivethreeone_state.dart';
import 'package:jackedlog/fivethreeone/schemes.dart';

import '../test_helpers.dart';

class _FakeTransport implements CoachTransport {
  _FakeTransport(this.responses);

  final List<Map<String, Object?>> responses;
  final List<List<Map<String, Object?>>> toolSets =
      <List<Map<String, Object?>>>[];

  @override
  Future<Map<String, Object?>> send({
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
  }) async {
    toolSets.add(tools.map(Map<String, Object?>.from).toList());
    return responses.removeAt(0);
  }
}

Map<String, Object?> _reply(String content) => <String, Object?>{
      'choices': <Object?>[
        <String, Object?>{
          'message': <String, Object?>{'content': content},
        },
      ],
    };

Map<String, Object?> _toolReply(
  String id,
  String name,
  Map<String, Object?> arguments,
) =>
    <String, Object?>{
      'choices': <Object?>[
        <String, Object?>{
          'message': <String, Object?>{
            'content': '',
            'tool_calls': <Object?>[
              <String, Object?>{
                'id': id,
                'type': 'function',
                'function': <String, Object?>{
                  'name': name,
                  'arguments': jsonEncode(arguments),
                },
              },
            ],
          },
        },
      ],
    };

Future<Map<String, Object?>> _snapshot(CoachTurn turn) async =>
    <String, Object?>{
      'exerciseVocabulary': <String>['Bench Press'],
      'unit': turn.unit,
    };

List<String> _names(List<Map<String, Object?>> tools) => tools
    .map(
      (tool) => (tool['function']! as Map<String, Object?>)['name']! as String,
    )
    .toList(growable: false);

ChatMessage _row(
  int id,
  String role, {
  String? content,
  String? toolCallId,
}) =>
    ChatMessage(
      id: id,
      role: role,
      content: content,
      toolCallId: toolCallId,
      created: DateTime(2026, 7, 29),
    );

Future<void> _insertBlock(AppDatabase database) async {
  await database.delete(database.fiveThreeOneBlocks).go();
  await database.into(database.fiveThreeOneBlocks).insert(
        FiveThreeOneBlocksCompanion.insert(
          created: DateTime(2026, 7, 29),
          squatTm: 140,
          benchTm: 100,
          deadliftTm: 180,
          pressTm: 60,
          unit: 'kg',
          currentCycle: const Value(cycleLeader2),
          currentWeek: const Value(2),
          leaderSupplemental: const Value(supplementalBbb),
          anchorSupplemental: const Value(supplementalFsl),
          tmBumps: const Value(1),
        ),
      );
}

const _correctTm = <String, Object?>{
  'op': 'correct_tm',
  'lift': 'bench',
  'value': 97.5,
};

const _rationale =
    'The book resets training maxes at the 7th week protocol, not mid-cycle.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() async {
    database = await createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  group('tool offering by tier', () {
    test('read tools are offered with no workout and no block', () async {
      final transport = _FakeTransport(<Map<String, Object?>>[
        _reply('Here is the trend.'),
      ]);
      final state = CoachState(snapshotBuilder: _snapshot);
      await state.openThread(null);
      await state.send(
        'how has my bench trended?',
        transport: transport,
        turn: const CoachTurn(block: null, workout: null, unit: 'kg'),
      );

      final names = _names(transport.toolSets.single);
      expect(names, containsAll(readToolNames));
      expect(names, isNot(contains(applySessionChangesTool)));
      expect(names, isNot(contains(proposeBlockChangesTool)));
    });

    test('propose_block_changes is offered only with an active block',
        () async {
      final withoutBlock = _FakeTransport(<Map<String, Object?>>[
        _reply('No block.'),
      ]);
      final state = CoachState(snapshotBuilder: _snapshot);
      await state.openThread(null);
      await state.send(
        'bump my TMs',
        transport: withoutBlock,
        turn: const CoachTurn(block: null, workout: null, unit: 'kg'),
      );
      expect(
        _names(withoutBlock.toolSets.single),
        isNot(contains(proposeBlockChangesTool)),
      );

      await _insertBlock(database);
      final fiveThreeOne = FiveThreeOneState();
      await fiveThreeOne.refresh();
      addTearDown(fiveThreeOne.dispose);

      final withBlock = _FakeTransport(<Map<String, Object?>>[
        _reply('Block present.'),
      ]);
      await state.send(
        'bump my TMs',
        transport: withBlock,
        turn: CoachTurn(
          block: fiveThreeOne.activeBlock,
          workout: null,
          unit: 'kg',
        ),
      );
      final names = _names(withBlock.toolSets.single);
      expect(names, contains(proposeBlockChangesTool));
      // No workout: the auto-apply tier stays closed even with a block.
      expect(names, isNot(contains(applySessionChangesTool)));
    });
  });

  group('tool dispatch', () {
    test('read tool calls run through runReadTool', () async {
      final transport = _FakeTransport(<Map<String, Object?>>[
        _toolReply('call-1', getBlockHistoryTool, <String, Object?>{}),
        _reply('You have no completed blocks yet.'),
      ]);
      final state = CoachState(snapshotBuilder: _snapshot);
      await state.openThread(null);
      await state.send(
        'am I progressing across blocks?',
        transport: transport,
        turn: CoachTurn(
          block: null,
          workout: null,
          unit: 'kg',
          completedBlocks: () async => <FiveThreeOneBlock>[],
        ),
      );

      final toolRow =
          state.messages.firstWhere((message) => message.role == 'tool');
      final result =
          Map<String, Object?>.from(jsonDecode(toolRow.content!) as Map);
      expect(result['ok'], isTrue);
      expect(result['text'], contains('No completed blocks yet.'));
    });

    test('a bad read-tool argument comes back as a retryable tool error',
        () async {
      final transport = _FakeTransport(<Map<String, Object?>>[
        _toolReply('call-1', getExerciseHistoryTool, <String, Object?>{
          'exercise': 'Bench Pres',
        }),
        _reply('Retrying with the exact name.'),
      ]);
      final state = CoachState(snapshotBuilder: _snapshot);
      await state.openThread(null);
      await state.send(
        'bench history',
        transport: transport,
        turn: const CoachTurn(block: null, workout: null, unit: 'kg'),
      );

      final toolRow =
          state.messages.firstWhere((message) => message.role == 'tool');
      final result =
          Map<String, Object?>.from(jsonDecode(toolRow.content!) as Map);
      expect(result['ok'], isFalse);
      expect(result['error'], contains('Bench Press'));
      // The turn continued instead of aborting.
      expect(state.error, isNull);
      expect(state.messages.last.role, 'assistant');
    });

    test('propose_block_changes returns a proposal and writes nothing',
        () async {
      await _insertBlock(database);
      final fiveThreeOne = FiveThreeOneState();
      await fiveThreeOne.refresh();
      addTearDown(fiveThreeOne.dispose);

      final transport = _FakeTransport(<Map<String, Object?>>[
        _toolReply('call-1', proposeBlockChangesTool, <String, Object?>{
          'ops': <Object?>[_correctTm],
          'rationale': _rationale,
        }),
        _reply('Confirm the correction below.'),
      ]);
      final state = CoachState(snapshotBuilder: _snapshot);
      await state.openThread(null);
      await state.send(
        'my bench TM is wrong, should be 97.5',
        transport: transport,
        turn: CoachTurn(
          block: fiveThreeOne.activeBlock,
          workout: null,
          unit: 'kg',
        ),
      );

      final toolRow =
          state.messages.firstWhere((message) => message.role == 'tool');
      final result =
          Map<String, Object?>.from(jsonDecode(toolRow.content!) as Map);
      expect(result['status'], 'pending_confirmation');
      expect(result['proposal'], isNotNull);

      // Nothing block-level is written by the proposal itself.
      final block = await database.select(database.fiveThreeOneBlocks).getSingle();
      expect(block.benchTm, 100);
      expect(block.tmBumps, 1);
      expect(state.sessionRevision, 0);
    });
  });

  group('confirmation outcomes', () {
    late FiveThreeOneState fiveThreeOne;

    setUp(() async {
      await _insertBlock(database);
      fiveThreeOne = FiveThreeOneState();
      await fiveThreeOne.refresh();
    });

    tearDown(() => fiveThreeOne.dispose());

    Future<BlockProposal> build() async {
      final result = await proposeBlockChanges(
        arguments: <String, Object?>{
          'ops': <Object?>[_correctTm],
          'rationale': _rationale,
        },
        block: fiveThreeOne.activeBlock,
        exerciseVocabulary: const <String>[],
        settingsUnit: 'kg',
      );
      expect(result['ok'], isTrue, reason: '${result['error']}');
      return BlockProposal.fromJson(
        Map<String, Object?>.from(result['proposal']! as Map),
      );
    }

    test('apply writes the block change and appends an applied row', () async {
      final state = CoachState(snapshotBuilder: _snapshot);
      await state.openThread(null);
      final proposal = await build();

      final result = await state.applyProposal(
        proposal: proposal,
        fiveThreeOneState: fiveThreeOne,
        unit: 'kg',
      );
      expect(result['status'], 'applied');

      final row = state.messages.last;
      expect(row.role, 'tool');
      final decoded = Map<String, Object?>.from(jsonDecode(row.content!) as Map);
      expect(decoded['status'], 'applied');
      expect(state.sessionRevision, 1);

      final block = await database.select(database.fiveThreeOneBlocks).getSingle();
      expect(block.benchTm, 97.5);
      // correct_tm must never touch the cycle-bump counter.
      expect(block.tmBumps, 1);
    });

    test('dismiss appends a declined row and writes nothing', () async {
      final state = CoachState(snapshotBuilder: _snapshot);
      await state.openThread(null);
      final proposal = await build();

      await state.declineProposal(proposal);

      final row = state.messages.last;
      expect(row.role, 'tool');
      final decoded = Map<String, Object?>.from(jsonDecode(row.content!) as Map);
      expect(decoded['status'], 'declined');
      expect(decoded['note'], contains('Nothing was written'));
      expect(state.sessionRevision, 0);

      final block = await database.select(database.fiveThreeOneBlocks).getSingle();
      expect(block.benchTm, 100);
      expect(block.tmBumps, 1);
    });
  });

  group('proposal rendering', () {
    late FiveThreeOneState fiveThreeOne;

    setUp(() async {
      await _insertBlock(database);
      fiveThreeOne = FiveThreeOneState();
      await fiveThreeOne.refresh();
    });

    tearDown(() => fiveThreeOne.dispose());

    Future<String> pendingJson() async {
      final result = await proposeBlockChanges(
        arguments: <String, Object?>{
          'ops': <Object?>[_correctTm],
          'rationale': _rationale,
        },
        block: fiveThreeOne.activeBlock,
        exerciseVocabulary: const <String>[],
        settingsUnit: 'kg',
      );
      return jsonEncode(result);
    }

    Future<void> pump(
      WidgetTester tester,
      List<ChatMessage> messages, {
      Future<void> Function(BlockProposal)? onApply,
      void Function(BlockProposal)? onDismiss,
    }) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoachMessageList(
                messages: messages,
                busy: false,
                error: null,
                onRetry: null,
                onApplyProposal: onApply,
                onDismissProposal: onDismiss,
              ),
            ),
          ),
        );

    testWidgets('a pending_confirmation result renders a ProposalCard',
        (tester) async {
      await pump(
        tester,
        <ChatMessage>[
          _row(1, 'user', content: 'my bench TM is wrong'),
          _row(2, 'tool', content: await pendingJson(), toolCallId: 'call-1'),
        ],
        onApply: (_) async {},
        onDismiss: (_) {},
      );

      final card = tester.widget<ProposalCard>(find.byType(ProposalCard));
      expect(card.status, ProposalCardStatus.pending);
      expect(card.onApply, isNotNull);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.textContaining('does not count'), findsOneWidget);
    });

    testWidgets('a later applied row flips the card without a volatile key',
        (tester) async {
      final messages = <ChatMessage>[
        _row(1, 'tool', content: await pendingJson(), toolCallId: 'call-1'),
      ];
      await pump(tester, messages, onApply: (_) async {}, onDismiss: (_) {});
      // The row's key is derived from its id alone, before and after.
      expect(find.byKey(const ValueKey<String>('coach-1')), findsOneWidget);

      messages.add(
        _row(
          2,
          'tool',
          content: jsonEncode(<String, Object?>{
            'ok': true,
            'status': 'applied',
            'applied': <Object?>[],
          }),
        ),
      );
      await pump(tester, messages, onApply: (_) async {}, onDismiss: (_) {});

      final card = tester.widget<ProposalCard>(find.byType(ProposalCard));
      expect(card.status, ProposalCardStatus.applied);
      expect(card.onApply, isNull);
      expect(find.text('Apply'), findsNothing);
      expect(find.byKey(const ValueKey<String>('coach-1')), findsOneWidget);
    });

    testWidgets('a later declined row marks the card dismissed',
        (tester) async {
      await pump(
        tester,
        <ChatMessage>[
          _row(1, 'tool', content: await pendingJson(), toolCallId: 'call-1'),
          _row(
            2,
            'tool',
            content: jsonEncode(<String, Object?>{
              'ok': true,
              'status': 'declined',
              'declined': <Object?>['correct_tm'],
            }),
          ),
        ],
        onApply: (_) async {},
        onDismiss: (_) {},
      );

      final card = tester.widget<ProposalCard>(find.byType(ProposalCard));
      expect(card.status, ProposalCardStatus.dismissed);
      expect(card.onDismiss, isNull);
      expect(find.text('No changes were written.'), findsOneWidget);
    });

    testWidgets('tapping Apply and Dismiss reaches the callbacks',
        (tester) async {
      BlockProposal? applied;
      BlockProposal? dismissed;
      await pump(
        tester,
        <ChatMessage>[
          _row(1, 'tool', content: await pendingJson(), toolCallId: 'call-1'),
        ],
        onApply: (proposal) async => applied = proposal,
        onDismiss: (proposal) => dismissed = proposal,
      );

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(dismissed, isNotNull);
      expect(applied, isNull);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(applied, isNotNull);

      // Tapping the card is the only thing that writes; the card itself did
      // not touch the block.
      final block = await database.select(database.fiveThreeOneBlocks).getSingle();
      expect(block.benchTm, 100);
      expect(block.tmBumps, 1);
    });
  });
}
