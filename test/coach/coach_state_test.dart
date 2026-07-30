import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:jackedlog/coach/coach_state.dart';
import 'package:jackedlog/coach/coach_tools.dart';
import 'package:jackedlog/coach/coach_transport.dart';
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

class _TransportCall {
  const _TransportCall({required this.messages, required this.tools});

  final List<Map<String, Object?>> messages;
  final List<Map<String, Object?>> tools;
}

class _FakeTransport implements CoachTransport {
  _FakeTransport({
    List<Object>? responses,
    this.always,
  }) : responses = responses ?? <Object>[];

  final List<Object> responses;
  final Map<String, Object?>? always;
  final List<_TransportCall> calls = <_TransportCall>[];

  @override
  Future<Map<String, Object?>> send({
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
  }) async {
    calls.add(
      _TransportCall(
        messages: messages.map(Map<String, Object?>.from).toList(),
        tools: tools.map(Map<String, Object?>.from).toList(),
      ),
    );
    final response = responses.isNotEmpty ? responses.removeAt(0) : always;
    if (response is Exception) throw response;
    return response! as Map<String, Object?>;
  }
}

Map<String, Object?> _reply(
  String? content, {
  List<Map<String, Object?>>? calls,
}) =>
    <String, Object?>{
      'choices': <Object?>[
        <String, Object?>{
          'message': <String, Object?>{
            'content': content,
            if (calls != null) 'tool_calls': calls,
          },
        },
      ],
    };

Map<String, Object?> _toolCall(
  String id, {
  String arguments = '{"ops":[]}',
}) =>
    <String, Object?>{
      'id': id,
      'type': 'function',
      'function': <String, Object?>{
        'name': applySessionChangesTool,
        'arguments': arguments,
      },
    };

Future<Map<String, Object?>> _snapshot(CoachTurn turn) async =>
    <String, Object?>{
      'exerciseVocabulary': <String>['Bench Press'],
      'unit': turn.unit,
      'workout': turn.workout?.id,
    };

const _noWorkoutTurn = CoachTurn(block: null, workout: null, unit: 'kg');

List<String> _names(List<Map<String, Object?>> tools) => tools
    .map((tool) => (tool['function']! as Map<String, Object?>)['name']! as String)
    .toList(growable: false);

void main() {
  late AppDatabase database;

  setUp(() async {
    database = await createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  Future<Workout> startWorkout() =>
      database.into(database.workouts).insertReturning(createTestWorkout());

  Future<List<ChatMessage>> rows() => (database.select(database.chatMessages)
        ..orderBy([
          (row) => OrderingTerm(expression: row.id),
        ]))
      .get();

  test('iteration cap stops after ten transport calls', () async {
    final workout = await startWorkout();
    final transport =
        _FakeTransport(always: _reply(null, calls: [_toolCall('loop')]));
    final state = CoachState(
      snapshotBuilder: _snapshot,
      toolInvoker: (_, __, ___) async => <String, Object?>{
        'ok': true,
        'applied': <Object?>[],
      },
    );
    await state.openThread(workout.id);

    await state.send(
      'keep going',
      transport: transport,
      turn: CoachTurn(block: buildBlock(), workout: workout, unit: 'kg'),
    );

    expect(transport.calls, hasLength(10));
    expect(state.busy, isFalse);
    final persisted = await rows();
    expect(persisted.last.role, 'assistant');
    expect(persisted.last.content, contains('Gave up after 10 steps'));
  });

  test('write tool is offered only with an active workout', () async {
    final withoutWorkout = _FakeTransport(responses: [_reply('Advice')]);
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(null);
    await state.send(
      'question',
      transport: withoutWorkout,
      turn: _noWorkoutTurn,
    );

    expect(
      jsonEncode(withoutWorkout.calls.single.tools),
      isNot(contains(applySessionChangesTool)),
    );

    final workout = await startWorkout();
    final withWorkout = _FakeTransport(responses: [_reply('Ready')]);
    await state.openThread(workout.id);
    await state.send(
      'write',
      transport: withWorkout,
      turn: CoachTurn(block: null, workout: workout, unit: 'kg'),
    );

    final tools = withWorkout.calls.single.tools;
    expect(_names(tools), contains(applySessionChangesTool));
  });

  test('training max basis follows active block availability', () async {
    final workout = await startWorkout();
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(workout.id);
    final withoutBlock = _FakeTransport(responses: [_reply('Done')]);
    await state.send(
      'no block',
      transport: withoutBlock,
      turn: CoachTurn(block: null, workout: workout, unit: 'kg'),
    );
    expect(
      jsonEncode(withoutBlock.calls.single.tools),
      isNot(contains('pct_of_tm')),
    );

    final withBlock = _FakeTransport(responses: [_reply('Done')]);
    await state.send(
      'with block',
      transport: withBlock,
      turn: CoachTurn(block: buildBlock(), workout: workout, unit: 'kg'),
    );
    expect(jsonEncode(withBlock.calls.single.tools), contains('pct_of_tm'));
  });

  test('tool errors are persisted and fed back for model correction', () async {
    final workout = await startWorkout();
    var invocations = 0;
    final state = CoachState(
      snapshotBuilder: _snapshot,
      toolInvoker: (_, __, ___) async {
        invocations++;
        if (invocations == 1) {
          return <String, Object?>{
            'ok': false,
            'error': 'unknown exercise',
          };
        }
        return <String, Object?>{'ok': true, 'applied': <Object?>[]};
      },
    );
    final transport = _FakeTransport(
      responses: [
        _reply(null, calls: [_toolCall('first')]),
        _reply(null, calls: [_toolCall('second')]),
        _reply('All fixed.'),
      ],
    );
    await state.openThread(workout.id);

    await state.send(
      'add work',
      transport: transport,
      turn: CoachTurn(block: buildBlock(), workout: workout, unit: 'kg'),
    );

    expect(invocations, 2);
    final persisted = await rows();
    expect(
      persisted.any(
        (row) =>
            row.role == 'tool' &&
            (row.content ?? '').contains('unknown exercise'),
      ),
      isTrue,
    );
    expect(
      transport.calls[1].messages.any(
        (message) =>
            message['role'] == 'tool' &&
            (message['content'] as String).contains('unknown exercise'),
      ),
      isTrue,
    );
    expect(persisted.last.content, 'All fixed.');
    expect(state.error, isNull);
  });

  test('plain reply takes one request and persists one assistant row',
      () async {
    final transport = _FakeTransport(responses: [_reply('Use FSL.')]);
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(null);

    await state.send(
      'What next?',
      transport: transport,
      turn: _noWorkoutTurn,
    );

    expect(transport.calls, hasLength(1));
    final assistantRows =
        (await rows()).where((row) => row.role == 'assistant').toList();
    expect(assistantRows, hasLength(1));
    expect(assistantRows.single.content, 'Use FSL.');
  });

  test('workout and ad-hoc threads never load each other', () async {
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(7);
    await state.send(
      'workout seven',
      transport: _FakeTransport(responses: [_reply('seven reply')]),
      turn: _noWorkoutTurn,
    );
    await state.openThread(null);
    expect(state.messages, isEmpty);
    await state.send(
      'ad hoc',
      transport: _FakeTransport(responses: [_reply('ad hoc reply')]),
      turn: _noWorkoutTurn,
    );

    await state.openThread(7);
    expect(state.messages.map((row) => row.content), contains('workout seven'));
    expect(state.messages.map((row) => row.content), isNot(contains('ad hoc')));
    await state.openThread(null);
    expect(state.messages.map((row) => row.content), contains('ad hoc'));
    expect(
      state.messages.map((row) => row.content),
      isNot(contains('workout seven')),
    );
  });

  test('first transport failure rolls user row back into the composer',
      () async {
    final state = CoachState(snapshotBuilder: _snapshot);
    final transport = _FakeTransport(
      responses: [
        CoachTransportException(
          'Could not reach the server. Check your connection.',
        ),
      ],
    );
    await state.openThread(null);

    await state.send(
      'restore me',
      transport: transport,
      turn: _noWorkoutTurn,
    );

    expect(state.error, contains('Could not reach'));
    expect(state.canRetry, isTrue);
    expect(state.draftRestore, 'restore me');
    expect(state.messages, isEmpty);
    expect(await rows(), isEmpty);

    state.clearDraftRestore();
    final retryTransport = _FakeTransport(responses: [_reply('Recovered.')]);
    await state.retry(transport: retryTransport, turn: _noWorkoutTurn);
    expect(state.messages.map((row) => row.content), contains('restore me'));
    expect(state.messages.last.content, 'Recovered.');
  });

  test('CURRENT_STATE is first and rebuilt for every iteration', () async {
    final workout = await startWorkout();
    var snapshots = 0;
    final state = CoachState(
      snapshotBuilder: (turn) async => <String, Object?>{
        'exerciseVocabulary': <String>['Bench Press'],
        'revision': ++snapshots,
      },
      toolInvoker: (_, __, ___) async =>
          <String, Object?>{'ok': true, 'applied': <Object?>[]},
    );
    final transport = _FakeTransport(
      responses: [
        _reply(null, calls: [_toolCall('once')]),
        _reply('Finished.'),
      ],
    );
    await state.openThread(workout.id);

    await state.send(
      'do it',
      transport: transport,
      turn: CoachTurn(block: buildBlock(), workout: workout, unit: 'kg'),
    );

    expect(transport.calls, hasLength(2));
    expect(
      transport.calls.every(
        (call) =>
            call.messages.first['role'] == 'user' &&
            (call.messages.first['content'] as String)
                .startsWith('CURRENT_STATE\n'),
      ),
      isTrue,
    );
    expect(
      transport.calls[0].messages.first['content'],
      contains('"revision":1'),
    );
    expect(
      transport.calls[1].messages.first['content'],
      contains('"revision":2'),
    );
  });

  test('the workout thread and the ad-hoc thread never mix', () async {
    final workout = await startWorkout();
    final state = CoachState(snapshotBuilder: _snapshot);

    await state.openThread(workout.id);
    await state.send(
      'in the gym',
      transport: _FakeTransport(responses: [_reply('Session answer')]),
      turn: CoachTurn(block: buildBlock(), workout: workout, unit: 'kg'),
    );

    await state.openThread(null);
    expect(state.messages, isEmpty);
    await state.send(
      'on the couch',
      transport: _FakeTransport(responses: [_reply('Ad-hoc answer')]),
      turn: _noWorkoutTurn,
    );
    expect(
      state.messages.map((row) => row.content),
      <String>['on the couch', 'Ad-hoc answer'],
    );

    await state.openThread(workout.id);
    expect(
      state.messages.map((row) => row.content),
      <String>['in the gym', 'Session answer'],
    );

    // Clearing one thread leaves the other intact.
    await state.clearThread();
    expect(state.messages, isEmpty);
    await state.openThread(null);
    expect(
      state.messages.map((row) => row.content),
      <String>['on the couch', 'Ad-hoc answer'],
    );
  });
}
