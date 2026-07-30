import 'dart:async';
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
    var response = responses.isNotEmpty ? responses.removeAt(0) : always;
    // A Future response parks the turn mid-flight, which is how a test holds one
    // conversation open while it works in another.
    if (response is Future<Map<String, Object?>>) response = await response;
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

  test('a new ad-hoc thread writes no row until its first message', () async {
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(null);

    expect(state.threadId, isNull);
    expect(state.threads, isEmpty, reason: 'nothing to list yet');

    await state.send(
      'how do i pick a training max?',
      transport: _FakeTransport(responses: [_reply('Start at 85%.')]),
      turn: _noWorkoutTurn,
    );

    expect(state.threadId, isNot(null));
    expect(state.threads, hasLength(1));
    expect(
      state.threads.single.title,
      'how do i pick a training max?',
      reason: 'the sidebar labels a thread by its first user message',
    );
  });

  test('the sidebar lists ad-hoc threads newest first and switches between them',
      () async {
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(null);
    await state.send(
      'first question',
      transport: _FakeTransport(responses: [_reply('first answer')]),
      turn: _noWorkoutTurn,
    );
    final first = state.threadId!;

    await state.startNewThread();
    expect(state.messages, isEmpty);
    await state.send(
      'second question',
      transport: _FakeTransport(responses: [_reply('second answer')]),
      turn: _noWorkoutTurn,
    );
    final second = state.threadId!;

    expect(
      state.threads.map((thread) => thread.id),
      <int>[second, first],
      reason: 'most recent activity first',
    );

    await state.openThreadById(first);
    expect(state.threadId, first);
    expect(state.messages.map((row) => row.content), contains('first question'));
    expect(
      state.messages.map((row) => row.content),
      isNot(contains('second question')),
    );
  });

  test('workout threads stay out of the sidebar', () async {
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(11);
    await state.send(
      'add the prescribed work',
      transport: _FakeTransport(responses: [_reply('Done.')]),
      turn: _noWorkoutTurn,
    );
    // A workout thread's write tools target the live session, so reopening it
    // from the Coach tab would put it in a context it was never written in.
    expect(state.threads, isEmpty);

    await state.openThread(null);
    expect(state.threads, isEmpty);
  });

  test('deleting a thread removes it and its messages', () async {
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(null);
    await state.send(
      'doomed',
      transport: _FakeTransport(responses: [_reply('ok')]),
      turn: _noWorkoutTurn,
    );
    final threadId = state.threadId!;

    await state.deleteThread(threadId);

    expect(state.threads, isEmpty);
    expect(state.threadId, isNull, reason: 'falls back to a fresh conversation');
    expect(state.messages, isEmpty);
    expect(await rows(), isEmpty);
  });

  test('reopening a workout thread mid-turn leaves the running turn alone',
      () async {
    final workout = await startWorkout();
    final gate = Completer<void>();
    final transport = _FakeTransport(
      responses: [_reply(null, calls: [_toolCall('call_slow')]), _reply('Done')],
    );
    final state = CoachState(
      snapshotBuilder: _snapshot,
      toolInvoker: (_, __, ___) async {
        await gate.future;
        return <String, Object?>{'ok': true, 'applied': <Object?>[]};
      },
    );
    await state.openThread(workout.id);
    final turn = CoachTurn(block: buildBlock(), workout: workout, unit: 'kg');
    final running = state.send('add sets', transport: transport, turn: turn);
    await pumpEventQueue();
    expect(state.busy, isTrue, reason: 'parked in the tool call');

    // The sheet reopening while the turn is in flight must not reload the
    // message list out from under the appends still to come.
    await state.openThread(workout.id);
    expect(state.messages, isNotEmpty, reason: 'not wiped by the reopen');
    gate.complete();
    await running;

    expect(state.messages.map((row) => row.role), <String>[
      'user',
      'assistant',
      'tool',
      'assistant',
    ]);
    expect(state.messages.map((row) => row.content), contains('Done'));
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
    expect(state.draftText, 'restore me');
    expect(state.messages, isEmpty);
    expect(await rows(), isEmpty);

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

  test('an unanswered tool call is answered before the thread is resent',
      () async {
    final workout = await startWorkout();

    // A turn interrupted between the tool call and its result: the provider
    // rejects a transcript with a dangling call, which would wedge the thread
    // for every later send.
    final thread = await database.into(database.chatThreads).insertReturning(
          ChatThreadsCompanion.insert(
            workoutId: Value(workout.id),
            created: DateTime.now(),
            updated: DateTime.now(),
          ),
        );
    await database.into(database.chatMessages).insert(
          ChatMessagesCompanion.insert(
            threadId: Value(thread.id),
            workoutId: Value(workout.id),
            role: 'assistant',
            toolCalls: Value(jsonEncode(<Object?>[_toolCall('call_dropped')])),
            created: DateTime.now(),
          ),
        );

    final transport = _FakeTransport(responses: [_reply('Back on track')]);
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(workout.id);
    await state.send(
      'try again',
      transport: transport,
      turn: CoachTurn(block: buildBlock(), workout: workout, unit: 'kg'),
    );

    final sent = transport.calls.single.messages;
    final repair = sent.firstWhere(
      (message) => message['tool_call_id'] == 'call_dropped',
    );
    expect(repair['role'], 'tool');
    expect(repair['content'], contains('interrupted'));
    // The repair rides along with the request without being stored.
    expect(
      (await rows()).where((row) => row.toolCallId == 'call_dropped'),
      isEmpty,
    );
    expect(state.error, isNull);
  });

  test('a reply lands in the conversation it was sent from, not the open one',
      () async {
    final gate = Completer<Map<String, Object?>>();
    final slow = _FakeTransport(responses: [gate.future]);
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(null);

    final running = state.send(
      'first question',
      transport: slow,
      turn: _noWorkoutTurn,
    );
    await pumpEventQueue();
    final first = state.threadId!;

    // Switch away while the reply is still in flight.
    await state.startNewThread();
    expect(state.busy, isFalse, reason: 'the new conversation is idle');
    expect(state.messages, isEmpty);

    gate.complete(_reply('first answer'));
    await running;

    expect(
      state.messages,
      isEmpty,
      reason: 'the reply belongs to the conversation it was asked in',
    );
    await state.openThreadById(first);
    expect(
      state.messages.map((row) => row.content),
      <String>['first question', 'first answer'],
    );
  });

  test('two conversations can run turns at once without mixing', () async {
    final firstGate = Completer<Map<String, Object?>>();
    final secondGate = Completer<Map<String, Object?>>();
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(null);

    final firstRun = state.send(
      'question one',
      transport: _FakeTransport(responses: [firstGate.future]),
      turn: _noWorkoutTurn,
    );
    await pumpEventQueue();
    final first = state.threadId!;
    expect(state.busy, isTrue);

    await state.startNewThread();
    final secondRun = state.send(
      'question two',
      transport: _FakeTransport(responses: [secondGate.future]),
      turn: _noWorkoutTurn,
    );
    await pumpEventQueue();
    final second = state.threadId!;
    expect(state.runningThreadIds, <int>{first, second});

    // Out of order on purpose: the second conversation answers first.
    secondGate.complete(_reply('answer two'));
    await secondRun;
    expect(
      state.messages.map((row) => row.content),
      <String>['question two', 'answer two'],
    );
    expect(state.runningThreadIds, <int>{first});

    firstGate.complete(_reply('answer one'));
    await firstRun;
    expect(state.runningThreadIds, isEmpty);
    expect(
      state.messages.map((row) => row.content),
      <String>['question two', 'answer two'],
      reason: 'the first answer stayed out of the open conversation',
    );

    await state.openThreadById(first);
    expect(
      state.messages.map((row) => row.content),
      <String>['question one', 'answer one'],
    );
  });

  test('a half-written prompt stays with its own conversation', () async {
    final state = CoachState(snapshotBuilder: _snapshot);
    await state.openThread(null);
    await state.send(
      'saved question',
      transport: _FakeTransport(responses: [_reply('saved answer')]),
      turn: _noWorkoutTurn,
    );
    final first = state.threadId!;
    state.draftText = 'half written';

    await state.startNewThread();
    expect(state.draftText, '', reason: 'a new conversation starts empty');
    state.draftText = 'other draft';

    await state.openThreadById(first);
    expect(state.draftText, 'half written');
  });

  test('deleting a conversation stops the turn still running in it', () async {
    final gate = Completer<Map<String, Object?>>();
    final state = CoachState(
      snapshotBuilder: _snapshot,
      toolInvoker: (_, __, ___) async =>
          <String, Object?>{'ok': true, 'applied': <Object?>[]},
    );
    await state.openThread(null);
    final running = state.send(
      'doomed question',
      transport: _FakeTransport(
        responses: [gate.future, _reply('never stored')],
      ),
      turn: _noWorkoutTurn,
    );
    await pumpEventQueue();
    final threadId = state.threadId!;

    await state.deleteThread(threadId);
    gate.complete(_reply(null, calls: [_toolCall('orphan')]));
    await running;

    expect(await rows(), isEmpty, reason: 'no orphan rows for a dead thread');
    expect(state.threads, isEmpty);
  });

  test('a disposed state still finishes the turn it is running', () async {
    final workout = await startWorkout();
    final transport = _FakeTransport(
      responses: [
        _reply(null, calls: [_toolCall('call_midflight')]),
        _reply('Applied'),
      ],
    );
    final state = CoachState(
      snapshotBuilder: _snapshot,
      toolInvoker: (_, __, ___) async => <String, Object?>{
        'ok': true,
        'applied': <Object?>[],
      },
    );
    await state.openThread(workout.id);

    // The in-workout sheet disposes its state the moment it closes, which can
    // land mid-turn; the tool result must still reach the database or the
    // thread is left with a dangling call.
    state.dispose();
    await state.send(
      'add sets',
      transport: transport,
      turn: CoachTurn(block: buildBlock(), workout: workout, unit: 'kg'),
    );

    final persisted = await rows();
    expect(persisted.map((row) => row.role), <String>[
      'user',
      'assistant',
      'tool',
      'assistant',
    ]);
    expect(persisted[2].toolCallId, 'call_midflight');
  });
}
